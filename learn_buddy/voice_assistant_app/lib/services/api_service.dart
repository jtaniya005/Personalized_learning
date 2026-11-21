import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/api_responses.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  String _baseUrl;
  final http.Client _client;

  ApiService({
    required String baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String newUrl) {
    var cleaned = newUrl.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    _baseUrl = cleaned;
  }

  Map<String, String> _defaultHeaders(String sessionId) {
    return {
      'Accept': 'application/json',
      'X-Session-ID': sessionId,
    };
  }

  /// Pings GET /api/health to check server status
  Future<HealthResponse> checkHealth() async {
    final uri = Uri.parse('$_baseUrl/api/health');
    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        return HealthResponse.fromJson(data);
      } else {
        throw ApiException(
          'Server returned status code ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw ApiException(
        'Cannot reach backend at $_baseUrl (${e.message}). Check URL/IP and ensure server is running.',
      );
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Connection failed: $e');
    }
  }

  /// Sends recorded audio file via multipart form to POST /api/ask
  Future<AskResponse> askAudio({
    required File audioFile,
    required String sessionId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/ask');

    try {
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll(_defaultHeaders(sessionId));

      // Determine mime type from extension
      final pathLower = audioFile.path.toLowerCase();
      final isWav = pathLower.endsWith('.wav');
      final mediaType = isWav
          ? MediaType('audio', 'wav')
          : MediaType('audio', 'm4a');

      // Attach file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
        contentType: mediaType,
      );
      request.files.add(multipartFile);

      final streamedResponse = await _client.send(request).timeout(
            const Duration(seconds: 45), // allow STT + LLM response time
          );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        return AskResponse.fromJson(data);
      } else {
        String errorDetail = response.body;
        try {
          final errJson = jsonDecode(response.body);
          if (errJson is Map && errJson.containsKey('detail')) {
            errorDetail = errJson['detail'].toString();
          }
        } catch (_) {}
        throw ApiException(
          'Server error (${response.statusCode}): $errorDetail',
          response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw ApiException(
        'Cannot reach backend at $_baseUrl (${e.message}).',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Voice ask failed: $e');
    }
  }

  /// Sends text message fallback to POST /api/chat
  Future<ChatResponse> chatText({
    required String message,
    required String sessionId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chat');

    try {
      final headers = _defaultHeaders(sessionId);
      headers['Content-Type'] = 'application/json';

      final body = jsonEncode({'message': message});

      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 35));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        return ChatResponse.fromJson(data);
      } else {
        String errorDetail = response.body;
        try {
          final errJson = jsonDecode(response.body);
          if (errJson is Map && errJson.containsKey('detail')) {
            errorDetail = errJson['detail'].toString();
          }
        } catch (_) {}
        throw ApiException(
          'Server error (${response.statusCode}): $errorDetail',
          response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw ApiException(
        'Cannot reach backend at $_baseUrl (${e.message}).',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Chat request failed: $e');
    }
  }

  /// Resets conversation history via POST /api/reset
  Future<ResetResponse> resetSession(String sessionId) async {
    final uri = Uri.parse('$_baseUrl/api/reset');

    try {
      final headers = _defaultHeaders(sessionId);
      final response = await _client
          .post(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        return ResetResponse.fromJson(data);
      } else {
        throw ApiException(
          'Failed to reset session (${response.statusCode}): ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Reset failed: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
