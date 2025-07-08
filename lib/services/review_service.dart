import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homeypark_mobile_application/model/review.dart';
import 'package:homeypark_mobile_application/services/base_service.dart';
import 'package:http/http.dart' as http;

class ReviewService extends BaseService {
  static final String baseUrl = "${BaseService.baseUrl}/reviews";
  static final _storage = const FlutterSecureStorage();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'session_token');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<List<Review>> getReviews({int? parkingId, int? userId}) async {
    final headers = await _getHeaders();
    String url = baseUrl;

    if (parkingId != null) {
      url += '?parkingId=$parkingId';
    } else if (userId != null) {
      url += '?userId=$userId';
    }

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Review.fromJson(item)).toList();
    } else {
      debugPrint("Error getReviews: ${response.statusCode}");
      return [];
    }
  }

  static Future<List<Review>> getReviewsByParkingId(int parkingId) async {
    return await getReviews(parkingId: parkingId);
  }

  static Future<List<Review>> getReviewsByUserId(int userId) async {
    return await getReviews(userId: userId);
  }

  static Future<Review?> getReviewById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Review.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      debugPrint("Review not found: $id");
      return null;
    } else {
      throw Exception('Failed to load review: ${response.statusCode}');
    }
  }

  static Future<Review> createReview({
    required int rating,
    required String comment,
    required int parkingId,
    required int userId,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
        'parkingId': parkingId,
        'userId': userId,
      }),
    );

    if (response.statusCode == 201) {
      return Review.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create review: ${response.body}');
    }
  }

  static Future<Review> updateReview(int id, {
    required int rating,
    required String comment,
  }) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode == 200) {
      return Review.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update review: ${response.body}');
    }
  }

  static Future<void> deleteReview(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete review: ${response.body}');
    }
  }
}