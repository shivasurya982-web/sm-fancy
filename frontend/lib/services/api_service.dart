import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'socket_service.dart';

class ApiService {
  static String? _token;
  static String? currentUserId;
  static String currentUserRole = 'user';
  static String currentUserName = '';
  static String currentUserEmail = '';

  // Increased timeout for local network stability
  static const Duration _timeout = Duration(seconds: 15);

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5050/api';
    }
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) return configuredBaseUrl;
    
    return 'http://10.1.12.165:5050/api';
  }

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    currentUserId = prefs.getString('userId');
    currentUserRole = prefs.getString('userRole') ?? 'user';
    currentUserName = prefs.getString('userName') ?? '';
    currentUserEmail = prefs.getString('userEmail') ?? '';

    if (currentUserId != null) {
      SocketService.connect(currentUserId!);
    }
  }

  static Future<Map<String, String>> authHeaders() async {
    return await _headers();
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    SocketService.disconnect();
    _token = null;
    currentUserId = null;
    currentUserRole = 'user';
    currentUserName = '';
    currentUserEmail = '';
  }

  static Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<dynamic> get(String endpoint, {int retries = 1}) async {
    final List<String> authRequired = ['/cart', '/orders', '/auth/me', '/users', '/analytics/dashboard'];
    if (authRequired.any((path) => endpoint.startsWith(path)) && !isLoggedIn) {
      return null;
    }
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: await _headers())
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      if (retries > 0 && _isNetworkError(e)) {
        return get(endpoint, retries: retries - 1);
      }
      _handleError(e, 'GET $endpoint');
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body, {int retries = 0}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      if (retries > 0 && _isNetworkError(e)) {
        return post(endpoint, body, retries: retries - 1);
      }
      _handleError(e, 'POST $endpoint');
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      _handleError(e, 'PUT $endpoint');
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl$endpoint'), headers: await _headers())
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      _handleError(e, 'DELETE $endpoint');
    }
  }

  static bool _isNetworkError(dynamic e) {
    return e is SocketException ||
          e is http.ClientException ||
          e is TimeoutException;
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid server response: ${response.statusCode}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    
    // If we are getting a 404 or 500, but it's valid JSON, throw the message
    throw Exception(data != null && data['message'] != null ? data['message'] : 'Request failed with status: ${response.statusCode}');
  }

  static void _handleError(dynamic e, String context) {
    debugPrint('API Error [$context]: $e');
    final errStr = e.toString();
    if (e is SocketException || errStr.contains('refused')) {
      throw Exception('Server unreachable. Check if your PC IP has changed or Firewall is blocking Port 5000. Current IP: $baseUrl');
    } else {
      throw Exception(errStr.contains('Timeout') ? 'Connection timed out. Server taking too long or wrong IP address.' : 'Error: $e');
    }
  }

  // ==========================
  // AUTH
  // ==========================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String recoveryHint = '',
  }) async {
    final data = await post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'recoveryHint': recoveryHint,
    });
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await post('/auth/login', {
      'email': email,
      'password': password,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('userId', data['user']['id'].toString());
    await prefs.setString('userRole', data['user']['role']);
    await prefs.setString('userName', data['user']['name']);
    await prefs.setString('userEmail', data['user']['email']);

    _token = data['token'];
    currentUserId = data['user']['id'].toString();
    currentUserRole = data['user']['role'];
    currentUserName = data['user']['name'];
    currentUserEmail = data['user']['email'];

    SocketService.connect(currentUserId!);
    return Map<String, dynamic>.from(data);
  }
}

class TimeoutException implements Exception {}
