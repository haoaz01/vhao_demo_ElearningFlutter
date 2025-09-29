import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/lesson_completion_model.dart';
import '../model/progress_model.dart';
import '../controllers/auth_controller.dart';

class ProgressRepository {
  static const String _baseUrl = 'http://192.168.1.219:8080/api/progress';
  static const String _host = 'http://192.168.1.219:8080';


  // --- THÊM PUBLIC GETTER/HELPER (mới) ---
  static String get host => _host;                         // http://...:8080
  static String get progressBaseUrl => _baseUrl;           // .../api/progress
  static String get authBase => '$host/api/auth';       // Nếu nơi khác cần /api/progress
  static Future<String?> getToken() async {           // Lấy token tập trung
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  int min(int a, int b) => a < b ? a : b;
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> debugToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final userId = prefs.getInt('userId');

    print('🔐 Debug Token Info:');
    print('   - Token exists: ${token != null}');
    print('   - Token length: ${token?.length ?? 0}');
    print('   - UserId: $userId');
    print('   - Token preview: ${token != null ? '...${token.substring(token.length - 10)}' : 'null'}');
  }

  Future<http.Response> _authenticatedRequest(
      String endpoint, {
        String method = 'GET',
        Map<String, dynamic>? body,
      }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final url = Uri.parse('$_baseUrl$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('🚀 Making request:');
      print('   - Method: $method');
      print('   - URL: $url');
      print('   - Headers: $headers');
      if (body != null) {
        print('   - Body: $body');
      }

      http.Response response;
      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Method not supported');
      }

      return response;
    } catch (e) {
      print('💥 Error in _authenticatedRequest: $e');
      rethrow;
    }
  }

  // ===================== QUIZ HISTORY (accuracy by day) =====================
  // Host gốc (khác với _baseUrl đang trỏ /api/progress)

  /// Lấy lịch sử tỉ lệ đúng theo ngày.
  /// Trả về List<Map> mỗi phần tử có: { day: DateTime, correct: int, total: int, percent: double }
  Future<List<Map<String, dynamic>>> getQuizDailyHistory({
    required int userId,
    int days = 7,
    int? gradeId,
    int? subjectId,
    int? quizTypeId,
    int? chapterId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final fromDate = DateTime.now().subtract(Duration(days: days));
      final uri = Uri.parse('$_baseUrl/accuracy/daily').replace(queryParameters: {
        'userId': '$userId',
        'fromDate': fromDate.toIso8601String(),
        if (gradeId != null) 'gradeId': '$gradeId',
        if (subjectId != null) 'subjectId': '$subjectId',
        if (quizTypeId != null) 'quizTypeId': '$quizTypeId',
        if (chapterId != null) 'chapterId': '$chapterId',
      });

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      print('🚀 Request Quiz Daily History: GET $uri');

      final res = await http.get(uri, headers: headers);

      if (res.statusCode != 200) {
        print('❌ History failed: ${res.statusCode}, body=${res.body}');
        throw Exception('History failed: ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        throw Exception(decoded['message'] ?? 'API returned error');
      }

      final list = (decoded['data'] as List).cast<Map<String, dynamic>>();

      return list.map((e) {
        return {
          'day': DateTime.parse(e['day'] as String),
          'correct': (e['correctSum'] as num).toInt(),
          'total': (e['totalSum'] as num).toInt(),
          'percent': (e['percentAccuracy'] as num).toDouble().clamp(0.0, 100.0),
        };
      }).toList();
    } catch (e) {
      print('💥 Error in getQuizDailyHistory: $e');
      rethrow;
    }
  }

  // Đánh dấu bài học đã hoàn thành
// Đánh dấu bài học đã hoàn thành
  Future<LessonCompletion> completeLesson(int userId, int lessonId) async {
    try {
      print('🌐 Sending complete lesson request...');
      print('   - URL: /complete-lesson');
      print('   - UserId: $userId');
      print('   - LessonId: $lessonId');

      final response = await _authenticatedRequest(
        '/complete-lesson',
        method: 'POST',
        body: {
          'userId': userId,
          'lessonId': lessonId,
        },
      );

      print('📥 Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Headers: ${response.headers}');
      print('   - Body length: ${response.body.length}');
      print('   - Body preview: ${response.body.substring(0, min(200, response.body.length))}...');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true) {
          print('✅ Lesson completion successful');
          return LessonCompletion.fromJson(data['data']);
        } else {
          print('❌ API returned error: ${data['message']}');
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('   - Full response: ${response.body}');
        throw Exception('Failed to complete lesson: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception in completeLesson: $e');
      rethrow;
    }
  }

  // Hủy đánh dấu hoàn thành
  Future<void> uncompleteLesson(int userId, int lessonId) async {
    final response = await _authenticatedRequest(
      '/uncomplete-lesson/user/$userId/lesson/$lessonId',
      method: 'DELETE',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Failed to uncomplete lesson: ${response.statusCode}');
    }
  }

  // Kiểm tra trạng thái hoàn thành
  Future<bool> checkLessonCompletion(int userId, int lessonId) async {
    final response = await _authenticatedRequest(
      '/check-completion/user/$userId/lesson/$lessonId',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data']['completed'] ?? false;
      } else {
        throw Exception(data['message'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Failed to check completion: ${response.statusCode}');
    }
  }

  // Lấy tiến trình theo môn học
  Future<Progress> getProgressBySubject(int userId, int subjectId) async {
    final response = await _authenticatedRequest(
      '/user/$userId/subject/$subjectId',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['success'] == true) {
        return Progress.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Failed to get progress: ${response.statusCode}');
    }
  }

  // Lấy tất cả tiến trình của user
  Future<List<Progress>> getProgressByUser(int userId) async {
    final response = await _authenticatedRequest('/user/$userId');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List<dynamic> dataList = data['data'] ?? [];
        return dataList.map((item) => Progress.fromJson(item)).toList();
      } else {
        throw Exception(data['message'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Failed to get progress: ${response.statusCode}');
    }
  }

  // Lấy tiến trình theo khối lớp
  Future<List<Progress>> getProgressByGrade(int userId, int grade) async {
    final response = await _authenticatedRequest('/user/$userId/grade/$grade');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List<dynamic> dataList = data['data'] ?? [];
        return dataList.map((item) => Progress.fromJson(item)).toList();
      } else {
        throw Exception(data['message'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Failed to get progress: ${response.statusCode}');
    }
  }
}