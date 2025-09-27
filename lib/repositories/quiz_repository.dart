import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/quiz_history_model.dart';
import '../model/quiz_model.dart';
import '../model/question_model.dart';
import '../model/choice_model.dart';
import '../model/quiz_result_model.dart';

class QuizRepository {
  final String baseUrl = "http://192.168.1.219:8080/api/quizzes";

  Future<List<Quiz>> getAllQuizzes() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Quiz.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load quizzes");
    }
  }

  Future<Quiz> getQuizById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return Quiz.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Quiz not found");
    }
  }

  Future<Quiz> getQuizByCode(String code) async {
    final response = await http.get(Uri.parse("$baseUrl/code/$code"));
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

    try {
      final uri = Uri.parse("$baseUrl/filter").replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Quiz.fromJson(json)).toList();
      } else {
        throw Exception("Failed to filter quizzes by subject and grade. Status: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Quiz>> getQuizzesByFilter(int gradeId, int subjectId, {int? quizTypeId}) async {
    final queryParams = {
      "gradeId": gradeId.toString(),
      "subjectId": subjectId.toString(),
      if (quizTypeId != null) "quizTypeId": quizTypeId.toString(),
    };

    final uri = Uri.parse("$baseUrl/filter").replace(queryParameters: queryParams);
    final response = await http.get(uri);

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
        "Authorization": "Bearer $authToken", // 🔥 Gắn token
      },
    );

    print("📤 Request: $uri");
    print("🔑 Token exists: ${authToken.isNotEmpty}");
    print("📥 Status: ${response.statusCode}");
    print("📥 Body: ${response.body}");

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

    Map<String, List<int>> answersWithStringKeys = {};
    userAnswers.forEach((key, value) {
      answersWithStringKeys[key.toString()] = value;
    });

    Map<String, dynamic> requestBody = {
      'userId': userId,
      'answers': answersWithStringKeys,
      'durationSeconds': durationSeconds,
    };

    final uri = Uri.parse("$baseUrl/$quizId/submit");
    final jsonBody = jsonEncode(requestBody);

    // 🔥 THÊM TOKEN VÀO HEADER
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $authToken",
    };

    print("📤 Sending request to: $uri");
    print("🔑 With token: ${authToken.substring(0, 20)}...");
    print("👤 User ID: $userId");

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonBody,
    );

    print("📥 Response status: ${response.statusCode}");
    print("📥 Response body: ${response.body}");

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
    final response = await http.get(Uri.parse("$baseUrl/$quizId/statistics"));
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

  /// 🔹 Lấy danh sách subject theo grade
  Future<List<Map<String, dynamic>>> getSubjectsByGrade(int gradeId) async {
    final uri = Uri.parse("$baseUrl/grades/$gradeId/subjects");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception("Failed to load subjects for grade $gradeId");
    }
  }

  Future<Map<String, dynamic>> getBestScoreForUser(int quizId, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');

    final uri = Uri.parse("$baseUrl/$quizId/users/$userId/best-score");

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (authToken != null && authToken.isNotEmpty) "Authorization": "Bearer $authToken",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      // Trả về null nếu không có kết quả
      return {};
    } else {
      throw Exception("Failed to load best score. Status: ${response.statusCode}, Body: ${response.body}");
    }
  }
}
