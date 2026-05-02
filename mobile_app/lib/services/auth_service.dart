import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  static const _tokenKey = 'dayaar_auth_token';
  static const _userKey = 'dayaar_auth_user';

  Future<User> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = _decodeResponse(response);
    final user = User.fromJson(data);
    await saveSession(user);
    return user;
  }

  Future<void> saveSession(User user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, user.token ?? '');
    await preferences.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<User?> loadStoredUser() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(_tokenKey);
    final userJson = preferences.getString(_userKey);

    if (token == null || token.isEmpty || userJson == null || userJson.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(userJson) as Map<String, dynamic>;
    return User.fromJson({...decoded, 'token': token});
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_userKey);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message'] ?? 'Request failed with ${response.statusCode}');
  }
}
