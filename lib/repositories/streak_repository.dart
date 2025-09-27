// lib/repositories/streak_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StreakRepository {
  // Đổi IP theo server của bạn
  static const String _apiBase = 'http://192.168.1.219:8080/api';

  Future<Map<String, dynamic>> getStreak(int userId) async {
    return _get('/streak/$userId');
  }

  Future<Map<String, dynamic>> touchStreak(int userId) async {
    return _post('/streak/$userId/touch');
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final uri = Uri.parse('$_apiBase$path');

    final res = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    });

    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    return {'statusCode': res.statusCode, 'data': body};
  }

  Future<Map<String, dynamic>> _post(String path,
      {Map<String, dynamic>? body}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final uri = Uri.parse('$_apiBase$path');

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: body == null ? null : jsonEncode(body),
    );

    final data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    return {'statusCode': res.statusCode, 'data': data};
  }
}
