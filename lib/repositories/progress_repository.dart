import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/lesson_completion_model.dart';
import '../model/progress_model.dart';

class ProgressRepository {
  // ====== CONFIG CHUNG ======
  static const String host = 'http://192.168.1.148:8080'; // CHỈNH 1 CHỖ NÀY

  static String get authBase    => '$host/api/auth';
  static String get progressBase=> '$host/api/progress'; // backend: /api/progress
  static String get streakBase  => '$host/api/streak';   // backend: /api/streak
  static String get quizzesBase => '$host/api/quizzes';  // backend: /api/quizzes

  // Singleton (tránh tạo nhiều instance lung tung)
  ProgressRepository._();
  static final ProgressRepository instance = ProgressRepository._();

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }
  // ✅ helper headers dùng chung cho các repo khác (StreakRepository đang cần)
  static Map<String, String> authHeaders(String? token) => {
    'Accept'      : 'application/json',
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  // static Map<String, String> _headers(String? token) => {
  //   'Accept': 'application/json',
  //   'Content-Type': 'application/json',
  //   if (token != null) 'Authorization': 'Bearer $token',
  // };

  Future<void> debugToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final userId = prefs.getInt('userId');
    final tail = token == null ? '' : token.substring(math.max(0, token.length - 10));

    // debug
    // ignore: avoid_print
    print('🔐 Token? ${token != null} | len=${token?.length ?? 0} | userId=$userId | tail=...$tail');
  }

  // Helper gọi API có auth
  Future<http.Response> _authRequest(
      String path, {
        String method = 'GET',
        Map<String, dynamic>? body,
      }) async {
    final token = await ProgressRepository.getToken();
    final url = Uri.parse('${ProgressRepository.progressBase}$path');
    final headers = authHeaders(token);

    switch (method) {
      case 'GET':
        return http.get(url, headers: headers);
      case 'POST':
        return http.post(url, headers: headers, body: body == null ? null : jsonEncode(body));
      case 'DELETE':
        return http.delete(url, headers: headers);
      default:
        throw Exception('Unsupported method: $method');
    }
  }

  // ========= Lesson completion =========

  /// POST /api/progress/complete-lesson  {userId, lessonId}
  Future<LessonCompletion> completeLesson(int userId, int lessonId) async {
    final res = await _authRequest(
      '/complete-lesson',
      method: 'POST',
      body: {'userId': userId, 'lessonId': lessonId},
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);
      if (data['success'] == true) {
        return LessonCompletion.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Unknown error');
    }
    throw Exception('Failed to complete lesson: ${res.statusCode} ${res.body}');
  }

  /// DELETE /api/progress/uncomplete-lesson/user/{userId}/lesson/{lessonId}
  Future<void> uncompleteLesson(int userId, int lessonId) async {
    final res = await _authRequest(
      '/uncomplete-lesson/user/$userId/lesson/$lessonId',
      method: 'DELETE',
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);
      if (data['success'] == true) return;
      throw Exception(data['message'] ?? 'Unknown error');
    }
    throw Exception('Failed to uncomplete lesson: ${res.statusCode} ${res.body}');
  }

  /// GET /api/progress/check-completion/user/{userId}/lesson/{lessonId}
  Future<bool> checkLessonCompletion(int userId, int lessonId) async {
    final res = await _authRequest('/check-completion/user/$userId/lesson/$lessonId');

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);
      if (data['success'] == true) {
        return (data['data']?['completed'] ?? false) as bool;
      }
      throw Exception(data['message'] ?? 'Unknown error');
    }
    throw Exception('Failed to check completion: ${res.statusCode} ${res.body}');
  }

  // ========= Progress =========

  /// GET /api/progress/user/{userId}
  Future<List<Progress>> getProgressByUser(int userId) async {
    final res = await _authRequest('/user/$userId');

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);
      if (data['success'] == true) {
        final List<dynamic> list = (data['data'] ?? []) as List<dynamic>;
        return list.map((e) => Progress.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception(data['message'] ?? 'Unknown error');
    }
    throw Exception('Failed to get progress: ${res.statusCode} ${res.body}');
  }

  /// GET /api/progress/user/{userId}/subject/{subjectId}
  Future<Progress> getProgressBySubject(int userId, int subjectId) async {
    final res = await _authRequest('/user/$userId/subject/$subjectId');

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);
      if (data['success'] == true) {
        return Progress.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Unknown error');
    }
    throw Exception('Failed to get progress by subject: ${res.statusCode} ${res.body}');
  }

  /// GET /api/progress/user/{userId}/grade/{grade}
  Future<List<Progress>> getProgressByGrade(int userId, int grade) async {
    final res = await _authRequest('/user/$userId/grade/$grade');

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);
      if (data['success'] == true) {
        final List<dynamic> list = (data['data'] ?? []) as List<dynamic>;
        return list.map((e) => Progress.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception(data['message'] ?? 'Unknown error');
    }
    throw Exception('Failed to get progress by grade: ${res.statusCode} ${res.body}');
  }
}
