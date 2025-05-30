import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/models/review_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:4002/api';
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

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _token = data['token'];
      return data;
    }
    throw _handleError(response);
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: json.encode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      _token = data['token'];
      return data;
    }
    throw _handleError(response);
  }

  static Future<List<VideoModel>> getVideos({
    String? category,
    String? search,
    int page = 1,
  }) async {
    final queryParams = {
      if (category != null) 'category': category,
      if (search != null) 'search': search,
      'page': page.toString(),
    };

    final response = await http.get(
      Uri.parse('$baseUrl/videos').replace(queryParameters: queryParams),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['videos'] as List)
          .map((json) => VideoModel.fromJson(json))
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
      return (data['videos'] as List)
          .map((json) => VideoModel.fromJson(json))
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
      Uri.parse('$baseUrl/videos/$videoId/reviews'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['reviews'] as List)
          .map(
            (json) => ReviewModel(
              id: json['id'],
              videoId: json['videoId'],
              comment: json['comment'],
              rating: json['rating'].toDouble(),
              timestamp: DateTime.parse(json['timestamp']),
            ),
          )
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
      Uri.parse('$baseUrl/videos/$videoId/reviews'),
      headers: _headers,
      body: json.encode({'comment': comment, 'rating': rating}),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return ReviewModel(
        id: data['id'],
        videoId: data['videoId'],
        comment: data['comment'],
        rating: data['rating'].toDouble(),
        timestamp: DateTime.parse(data['timestamp']),
      );
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
