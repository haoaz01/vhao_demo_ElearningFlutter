import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_elearning_application/model/daily_quiz_stat_model.dart';
import 'package:flutter_elearning_application/repositories/progress_repository.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/quiz_history_model.dart';
import '../model/quiz_model.dart';
import '../model/question_model.dart';
import '../model/choice_model.dart';
import '../model/quiz_result_model.dart';
import '../model/quiz_progress_model.dart';

class QuizRepository {
  final String baseUrl = "${ProgressRepository.host}/api/quizzes";
  // final String baseUrl = "http://192.168.1.118:8080/api/quizzes";
  Future<Map<String,String>> _authJsonHeaders() async {
    final token = await ProgressRepository.getToken();
    final h = ProgressRepository.authHeaders(token);
    h['Content-Type'] = 'application/json';
    return h;
    }

  Future<List<Quiz>> getAllQuizzes() async {
    final response = await http.get(Uri.parse(baseUrl), headers: await _authJsonHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Quiz.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load quizzes");
    }
  }

  Future<Quiz> getQuizById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"), headers: await _authJsonHeaders());
    if (response.statusCode == 200) {
      return Quiz.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Quiz not found");
    }
  }

  Future<Quiz> getQuizByCode(String code) async {
    final response = await http.get(Uri.parse("$baseUrl/code/$code"), headers: await _authJsonHeaders());
    if (response.statusCode == 200) {
      return Quiz.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Quiz not found");
    }
  }

  Future<List<Quiz>> getQuizzesBySubjectAndGrade(int gradeId, int subjectId) async {
    final queryParams = {
      "gradeId": gradeId.toString(),
      "subjectId": subjectId.toString(),
    };

    final uri = Uri.parse("$baseUrl/filter").replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _authJsonHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Quiz.fromJson(json)).toList();
    } else {
      throw Exception("Failed to filter quizzes by subject and grade. Status: ${response.statusCode}");
    }
  }

  Future<List<Quiz>> getQuizzesByFilter(int gradeId, int subjectId, {int? quizTypeId}) async {
    final queryParams = {
      "gradeId": gradeId.toString(),
      "subjectId": subjectId.toString(),
      if (quizTypeId != null) "quizTypeId": quizTypeId.toString(),
    };

    final uri = Uri.parse("$baseUrl/filter").replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _authJsonHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Quiz.fromJson(json)).toList();
    } else {
      throw Exception("Failed to filter quizzes");
    }
  }

  Future<List<Question>> getQuizQuestions(int quizId) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');

    if (authToken == null || authToken.isEmpty) {
      throw Exception("Authentication token not found. Please login again.");
    }

    final uri = Uri.parse("$baseUrl/$quizId/questions");

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $authToken",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Question.fromJson(json)).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception("Unauthorized. Please login again.");
    } else {
      throw Exception(
        "Failed to load quiz questions. Status: ${response.statusCode}, Body: ${response.body}",
      );
    }
  }

  Future<List<Choice>> getQuestionChoices(int questionId) async {
    final response = await http.get(Uri.parse("$baseUrl/questions/$questionId/choices"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Choice.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load choices");
    }
  }

  Future<QuizResult> submitQuiz(int quizId, Map<int, List<int>> userAnswers, int durationSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    final authToken = prefs.getString("authToken");

    if (userId == null) {
      throw Exception("UserId not found. Please login again.");
    }

    if (authToken == null || authToken.isEmpty) {
      throw Exception("Authentication token not found. Please login again.");
    }

    // convert key int -> string
    final Map<String, List<int>> answersWithStringKeys = {
      for (final entry in userAnswers.entries) entry.key.toString(): entry.value
    };

    final requestBody = {
      'userId': userId,
      'answers': answersWithStringKeys,
      'durationSeconds': durationSeconds,
    };

    final uri = Uri.parse("$baseUrl/$quizId/submit");

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $authToken",
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return QuizResult.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception("Authentication failed. Please login again.");
    } else {
      throw Exception("Failed to submit quiz. Status: ${response.statusCode}, Body: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getQuizStatistics(int quizId) async {
    final response = await http.get(Uri.parse("$baseUrl/$quizId/statistics"), headers: await _authJsonHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load statistics");
    }
  }

  Future<List<QuizHistory>> getQuizHistory(int quizId, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');

    final uri = Uri.parse("$baseUrl/$quizId/users/$userId/history");

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (authToken != null && authToken.isNotEmpty) "Authorization": "Bearer $authToken",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => QuizHistory.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load quiz history. Status: ${response.statusCode}, Body: ${response.body}");
    }
  }

  /// Lấy danh sách subject theo grade
  Future<List<Map<String, dynamic>>> getSubjectsByGrade(int gradeId) async {
    final uri = Uri.parse("$baseUrl/grades/$gradeId/subjects");
    final response = await http.get(uri, headers: await _authJsonHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception("Failed to load subjects for grade $gradeId");
    }
  }

  /// ✅ FIX: dùng token từ SharedPreferences và http.get trực tiếp
  Future<Map<String, dynamic>> getBestScoreForUser(int quizId, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');

    final uri = Uri.parse('$baseUrl/$quizId/users/$userId/best-score');
    final headers = {
      'Accept': 'application/json',
      if (authToken != null && authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };

    try {
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        if (res.body.trim().isEmpty) return {};
        final jsonMap = jsonDecode(res.body);
        return (jsonMap is Map<String, dynamic>) ? jsonMap : {};
      }

      // chưa có best score
      if (res.statusCode == 404 || res.statusCode == 204) return {};

      // các lỗi khác → không làm vỡ UI, trả {}
      debugPrint('getBestScoreForUser HTTP ${res.statusCode}: ${res.reasonPhrase}');
      return {};
    } catch (e) {
      debugPrint('getBestScoreForUser error: $e');
      return {};
    }
  }

  Future<QuizProgressModel> getQuizProgress({
    required int userId,
    int? gradeId,
    int? subjectId,
    int? quizTypeId,
    int? chapterId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');

    final uri = Uri.parse("$baseUrl/progress").replace(queryParameters: {
      'userId': '$userId',
      if (gradeId != null) 'gradeId': '$gradeId',
      if (subjectId != null) 'subjectId': '$subjectId',
      if (quizTypeId != null) 'quizTypeId': '$quizTypeId',
      if (chapterId != null) 'chapterId': '$chapterId',
    });

    final res = await http.get(uri, headers: {
      "Content-Type": "application/json",
      if (authToken != null && authToken.isNotEmpty) "Authorization": "Bearer $authToken",
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return QuizProgressModel.fromJson(data);
    } else {
      throw Exception("Failed to load quiz progress: ${res.statusCode} ${res.body}");
    }
  }

  Future<List<QuizDailyStat>> getQuizDailyAccuracy({
    required int userId,
    int days = 7,
    int? gradeId,
    int? subjectId,
    int? quizTypeId,
    int? chapterId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');

    final uri = Uri.parse("$baseUrl/history").replace(queryParameters: {
      'userId': '$userId',
      'days': '$days',
      if (gradeId != null) 'gradeId': '$gradeId',
      if (subjectId != null) 'subjectId': '$subjectId',
      if (quizTypeId != null) 'quizTypeId': '$quizTypeId',
      if (chapterId != null) 'chapterId': '$chapterId',
    });

    final res = await http.get(uri, headers: {
      "Content-Type": "application/json",
      if (authToken != null && authToken.isNotEmpty) "Authorization": "Bearer $authToken",
    });

    if (res.statusCode == 200) {
      final List<dynamic> arr = jsonDecode(res.body);
      return arr.map((e) => QuizDailyStat.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception("Failed to load quiz history: ${res.statusCode} ${res.body}");
    }
  }
}
