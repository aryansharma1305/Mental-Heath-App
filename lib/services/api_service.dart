import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Get base URL from .env or use default
  String get baseUrl {
    try {
      if (dotenv.env.containsKey('API_BASE_URL') && 
          dotenv.env['API_BASE_URL'] != null &&
          dotenv.env['API_BASE_URL']!.isNotEmpty) {
        return dotenv.env['API_BASE_URL']!;
      }
    } catch (e) {
      // dotenv not loaded, use default
    }
    return 'https://api.healthcare.org';
  }

  // Get timeout duration
  Duration get timeout => const Duration(seconds: 30);

  // Get headers with authentication
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http
          .get(
            uri,
            headers: await _getHeaders(includeAuth: includeAuth),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http
          .post(
            uri,
            headers: await _getHeaders(includeAuth: includeAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      // Return a failure response that can be caught by caller
      // Don't include full error message to avoid exposing network details
      throw Exception('Network unavailable');
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http
          .put(
            uri,
            headers: await _getHeaders(includeAuth: includeAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http
          .delete(
            uri,
            headers: await _getHeaders(includeAuth: includeAuth),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  // Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          ...data,
        };
      } else if (response.statusCode == 401) {
        // Unauthorized - token might be expired
        // Token refresh should be handled by AuthService
        return {
          'success': false,
          'message': 'Unauthorized. Please login again.',
          'statusCode': response.statusCode,
          'requiresAuth': true,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Request failed',
          'statusCode': response.statusCode,
          ...data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to parse response: ${e.toString()}',
        'statusCode': response.statusCode,
      };
    }
  }

  // Upload file
  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    List<int> fileBytes,
    String fileName, {
    Map<String, String>? fields,
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final headers = await _getHeaders(includeAuth: includeAuth);
      request.headers.addAll(headers);

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Upload error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }
}

