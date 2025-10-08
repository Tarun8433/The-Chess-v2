import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

/// Authentication service for API calls
class AuthService {
  static const String _baseUrl =
      'https://chessgame.signaturesoftware.co.in/api/CS';

  /// Register a new user
  static Future<ApiResponse<UserModel>> registerUser({
    required String userName,
    required String password,
    required String mobileNo,
    required String emailAddress,
    required String countryCode,
    required String countryName,
  }) async {
    try {
      final body = {
        'UserName': userName,
        'Password': password,
        'MobileNo': mobileNo,
        'EmailAddress': emailAddress,
        'countrycode': countryCode,
        'countryname': countryName,
        'UserName_Uniq': userName,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/Registration'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['Status'] == true;

      if (status && json['Response'] != null) {
        final responseList = json['Response'] as List<dynamic>;
        if (responseList.isNotEmpty) {
          final userData = responseList.first as Map<String, dynamic>;
          final user = UserModel.fromJson(userData);
          return ApiResponse.success(
              user, json['Message']?.toString() ?? 'Registration successful');
        }
      }

      return ApiResponse.error(
          json['Message']?.toString() ?? 'Registration failed');
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Check if username is available
  static Future<bool> isUsernameAvailable(String userName) async {
    try {
      final body = {
        'UserId': userName,
        'PackageId': '',
        'countryid': '',
        'Brandid': '',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/GetUserUniqName'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) return false;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final responseList = (json['Response'] ?? []) as List<dynamic>;

      if (responseList.isEmpty) return false;

      final first = responseList.first as Map<String, dynamic>;
      final msg = (first['msg'] ?? '').toString().toLowerCase();

      return msg.contains('available') || first['id']?.toString() == '0';
    } catch (_) {
      return false;
    }
  }

  /// Login user with actual API endpoint
  static Future<ApiResponse<UserModel>> loginUser({
    required String userName,
    required String password,
    String tokenNo = '',
  }) async {
    try {
      final body = {
        'UserName': userName,
        'Password': password,
        'TokenNo': tokenNo,
      };

      log('Login API Request - URL: $_baseUrl/Login');
      log('Login API Request - Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/Login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      log('Login API Response - Status Code: ${response.statusCode}');
      log('Login API Response - Raw Body: ${response.body}');

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['Status'] == true;
      final message = json['Message']?.toString() ?? '';
      final statusCode = json['StatusCode']?.toString() ?? '';

      log('Login API Response - Parsed Status: $status');
      log('Login API Response - Status Code: $statusCode');
      log('Login API Response - Message: $message');

      if (status && json['Response'] != null) {
        final responseList = json['Response'] as List<dynamic>;
        log('Login API Response - Response List Length: ${responseList.length}');

        if (responseList.isNotEmpty) {
          final userData = responseList.first as Map<String, dynamic>;
          log('Login API Response - User Data: $userData');
          final user = UserModel.fromJson(userData);
          return ApiResponse.success(
              user, message.isEmpty ? 'Login successful' : message);
        }
      }

      log('Login API Response - Login Failed: $message');
      return ApiResponse.error(message.isEmpty ? 'Login failed' : message);
    } catch (e) {
      log('Login API Error - Exception: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }
}

/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;

  ApiResponse._({
    required this.success,
    this.data,
    required this.message,
  });

  factory ApiResponse.success(T data, [String message = 'Success']) {
    return ApiResponse._(success: true, data: data, message: message);
  }

  factory ApiResponse.error(String message) {
    return ApiResponse._(success: false, message: message);
  }
}
