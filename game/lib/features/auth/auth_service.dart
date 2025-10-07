import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseRegistrationUrl =
      'https://chessgame.signaturesoftware.co.in/api/CS/Registration';
  static const String _baseGetUserUniqNameUrl =
      'https://chessgame.signaturesoftware.co.in/api/CS/GetUserUniqName';

  static Future<Map<String, dynamic>> registerUser({
    required String userName,
    required String password,
    required String mobileNo,
    required String emailAddress,
    required String countryCode,
    required String countryName,
    required String userNameUniq,
  }) async {
    final body = {
      'UserName': userName,
      'Password': password,
      'MobileNo': mobileNo,
      'EmailAddress': emailAddress,
      'countrycode': countryCode,
      'countryname': countryName,
      'UserName_Uniq': userNameUniq,
    };
    final resp = await http.post(
      Uri.parse(_baseRegistrationUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    final Map<String, dynamic> json = jsonDecode(resp.body);
    return json;
  }

  static Future<bool> isUserNameAvailable(String userName) async {
    final body = {
      'UserId': userName,
      'PackageId': '',
      'countryid': '',
      'Brandid': '',
    };
    final resp = await http.post(
      Uri.parse(_baseGetUserUniqNameUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) return false;
    final Map<String, dynamic> json = jsonDecode(resp.body);
    try {
      final List<dynamic> responseArr = (json['Response'] ?? []) as List<dynamic>;
      if (responseArr.isEmpty) return false;
      final Map<String, dynamic> first = responseArr.first as Map<String, dynamic>;
      final msg = (first['msg'] ?? '').toString().toLowerCase();
      if (msg.contains('available')) return true;
      if (first['id']?.toString() == '0') return true;
      return false;
    } catch (_) {
      return false;
    }
  }
}