import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS simulator/desktop
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    return 'http://127.0.0.1:8000/api/v1';
  }

  static Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    required int studentClass,
    required int avatarIndex,
    required List<String> weakSubjects,
    required int dailyGoalMinutes,
    String? stream,
  }) async {
    final url = Uri.parse('$baseUrl/user/profile');
    try {
      final token = await _getToken();
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          'student_class': studentClass,
          'avatar_index': avatarIndex,
          'weak_subjects': weakSubjects,
          'daily_goal_minutes': dailyGoalMinutes,
          if (stream != null) 'stream': stream,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Profile update failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> extractMarksheet(Uint8List bytes, String filename) async {
    final url = Uri.parse('$baseUrl/students/me/marksheet/extract');
    try {
      var request = http.MultipartRequest('POST', url);
      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['detail']?.toString() ?? 'Failed to extract',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> saveMarksheet(Map<String, dynamic> marksData) async {
    final url = Uri.parse('$baseUrl/students/me/marksheet/save');
    try {
      final token = await _getToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(marksData),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Failed to save marks'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }
}
