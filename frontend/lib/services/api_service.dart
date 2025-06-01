import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/models/review_model.dart';
import 'package:flutter_video_app/models/user_model.dart'; // Added UserModel import

class ApiService {
  static const String baseUrl = 'http://192.168.231.1:4002/api';
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  static Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _token = data['token'] as String?;
      return UserModel.fromJson(
        data['user'] as Map<String, dynamic>,
      ); // Return UserModel
    }
    throw _handleError(response);
  }

  static Future<List<String>> getMovieTypes() async {
    // Or rename to getGenres()
    final response = await http.get(
      Uri.parse('$baseUrl/genres'), // Updated endpoint
      headers: {'Content-Type': 'application/json'}, // Keep headers as needed
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // New backend sends { success: true, genres: types }
      final typesList =
          responseData['genres'] as List?; // Changed 'data' to 'genres'
      return List<String>.from(typesList ?? []);
    }
    throw _handleError(response); // Existing error handling
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
    bool loadAll = false,
  }) async {
    final queryParams = {
      if (category != null) 'category': category,
      if (search != null) 'search': search,
      if (page != null) 'page': page.toString(),
      'loadAll': loadAll.toString(),
    };

    final response = await http.get(
      Uri.parse('$baseUrl/movies').replace(queryParameters: queryParams),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Based on movie.controller.js getAllMovies, it's res.status(200).json({ success: true, movies: mappedMovies, ...});
      return (data['movies'] as List)
          .map((json) => VideoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw _handleError(response);
  }

  static Future<List<VideoModel>> getFavorites() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/favorites'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Backend getUserFavorites returns { success: true, data: mappedFavorites }
      return (data['data'] as List)
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

  // Reviews endpoints
  static Future<List<ReviewModel>> getVideoReviews(String videoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movies/$videoId/reviews'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Backend getMovieReviews returns { success: true, count: ..., data: mappedReviews }
      return (data['data'] as List)
          .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw _handleError(response);
  }

  static Future<ReviewModel> addReview(
    String videoId,
    String comment,
    double rating,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/movies/$videoId/reviews'),
      headers: _headers,
      body: json.encode({'comment': comment, 'rating': rating}),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      // Backend addMovieReview returns { success: true, data: { ...mappedReview... } }
      return ReviewModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw _handleError(response);
  }

  static Future<UserModel> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Backend getMe returns { success: true, data: { id: ..., name: ..., ... } }
      return UserModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw _handleError(response);
  }

  static Exception _handleError(http.Response response) {
    try {
      final error = json.decode(response.body)['message'];
      return Exception(error ?? 'An error occurred');
    } catch (e) {
      return Exception('An error occurred');
    }
  }
}
