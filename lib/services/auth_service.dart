import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class AuthService {
  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS simulator/desktop
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    return 'http://127.0.0.1:8000/api/v1';
  }

  static String? accessToken;

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required int studentClass,
    required int avatarIndex,
    required List<String> weakSubjects,
    required int dailyGoalMinutes,
    String? stream,
    List<Map<String, dynamic>>? previousTestMarks,
    double? previousClassPercentage,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'student_class': studentClass,
          'avatar_index': avatarIndex,
          'weak_subjects': weakSubjects,
          'daily_goal_minutes': dailyGoalMinutes,
          if (stream != null) 'stream': stream,
          if (previousTestMarks != null) 'previous_test_marks': previousTestMarks,
          if (previousClassPercentage != null) 'previous_class_percentage': previousClassPercentage,
        }),
      ).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        accessToken = data['access_token'];
        return {
          'success': true,
          'data': data,
        };
      } else {
        String errMsg = 'Registration failed';
        if (data['detail'] is List) {
          errMsg = (data['detail'] as List).map((e) => e['msg'].toString()).join('\\n');
        } else if (data['detail'] != null) {
          errMsg = data['detail'].toString();
        }
        return {
          'success': false,
          'message': errMsg,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required int studentClass,
    required int avatarIndex,
    required List<String> weakSubjects,
    required int dailyGoalMinutes,
    String? stream,
  }) async {
    final url = Uri.parse('$baseUrl/user/profile');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
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
      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
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
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
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
