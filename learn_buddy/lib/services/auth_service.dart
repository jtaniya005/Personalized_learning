import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static String? _cachedToken;
  static Map<String, dynamic>? _cachedUser;

  static String _activePort = '8001';
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:$_activePort/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:$_activePort/api/v1';
    return 'http://127.0.0.1:$_activePort/api/v1';
  }

  static void setActivePort(String port) {
    _activePort = port;
  }

  static Map<String, dynamic>? get currentUser => _cachedUser;

  static Future<String?> _getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_jwt_token');
    if (_cachedToken != null) return _cachedToken;

    // Fallback to Firebase token if logged in through Firebase
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    _cachedToken = token;
    _cachedUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_jwt_token', token);
    await prefs.setString('auth_user_json', jsonEncode(user));
  }

  static Future<void> logout() async {
    _cachedToken = null;
    _cachedUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_jwt_token');
    await prefs.remove('auth_user_json');
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_jwt_token');
    final userJson = prefs.getString('auth_user_json');
    if (token != null && userJson != null) {
      _cachedToken = token;
      _cachedUser = jsonDecode(userJson);
      return true;
    }
    return false;
  }

  /// Register student in backend DB with unique ID
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required int studentClass,
    String? school,
    String? board,
    String? stream,
    List<String>? subjects,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email.trim().toLowerCase(),
          'password': password,
          'student_class': studentClass,
          'school': school,
          'board': board,
          'stream': stream,
          'subjects': subjects ?? [],
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        final token = data['access_token'];
        final user = data['user'] as Map<String, dynamic>;
        await _saveSession(token, user);
        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': data['detail'] ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Login student with email and password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final token = data['access_token'];
        final user = data['user'] as Map<String, dynamic>;
        await _saveSession(token, user);
        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': data['detail'] ?? 'Invalid credentials'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Update student academic details
  static Future<Map<String, dynamic>> updateDetails({
    String? name,
    int? studentClass,
    String? school,
    String? board,
    String? stream,
    List<String>? subjects,
    int? avatarIndex,
    String? profilePhoto,
    int? dailyGoalMinutes,
  }) async {
    final url = Uri.parse('$baseUrl/auth/details');
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
          if (studentClass != null) 'student_class': studentClass,
          if (school != null) 'school': school,
          if (board != null) 'board': board,
          if (stream != null) 'stream': stream,
          if (subjects != null) 'subjects': subjects,
          if (avatarIndex != null) 'avatar_index': avatarIndex,
          if (profilePhoto != null) 'profile_photo': profilePhoto,
          if (dailyGoalMinutes != null) 'daily_goal_minutes': dailyGoalMinutes,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _cachedUser = data;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_user_json', jsonEncode(data));
        return {'success': true, 'user': data};
      }
      return {'success': false, 'message': data['detail'] ?? 'Update failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Fetch full user profile
  static Future<Map<String, dynamic>?> getProfile() async {
    final url = Uri.parse('$baseUrl/user/profile');
    try {
      final token = await _getToken();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final user = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_user_json', jsonEncode(user));
        return user;
      }
      return _cachedUser;
    } catch (e) {
      debugPrint('getProfile failed: $e');
      return _cachedUser;
    }
  }

  /// Marksheet extraction via Tesseract with validation check
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
        'message': data['detail']?.toString() ?? 'Invalid marksheet',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Save edited / confirmed marksheet & generate categorization + study plan
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
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data['user'] != null) {
          _cachedUser = data['user'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_user_json', jsonEncode(data['user']));
        }
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['detail'] ?? 'Failed to save marks'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Send AI mentor chat message with category persona & ChromaDB memory
  static Future<Map<String, dynamic>> sendChatMessage(String message, {String subject = 'General'}) async {
    final url = Uri.parse('$baseUrl/chat/message');
    try {
      final token = await _getToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
          'subject': subject,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['detail'] ?? 'Chat request failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get past chat interactions from ChromaDB
  static Future<List<Map<String, dynamic>>> getChatHistory() async {
    final url = Uri.parse('$baseUrl/chat/history');
    try {
      final token = await _getToken();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['history'] as List? ?? [])
            .map((item) => item as Map<String, dynamic>)
            .toList();
        return list;
      }
      return [];
    } catch (e) {
      debugPrint('getChatHistory failed: $e');
      return [];
    }
  }
}
