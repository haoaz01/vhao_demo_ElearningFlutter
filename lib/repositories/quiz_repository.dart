import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/quiz_model.dart';
import '../model/question_model.dart';
import '../model/choice_model.dart';
import '../model/quiz_result_model.dart';

class QuizRepository {
  final String baseUrl = "http://192.168.0.144:8080/api/quizzes";

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
    final response = await http.get(Uri.parse("$baseUrl/$quizId/questions"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Question.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load quiz questions");
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

    if (userId == null) {
      throw Exception("UserId not found. Please login again.");
    }

    // Convert answers to use string keys (JSON requires string keys)
    Map<String, List<int>> answersWithStringKeys = {};
    userAnswers.forEach((key, value) {
      answersWithStringKeys[key.toString()] = value;
    });

    // Create request body - send userId as number
    Map<String, dynamic> requestBody = {
      'userId': userId, // Send as number, not string
      'answers': answersWithStringKeys,
      'durationSeconds': durationSeconds,
    };

    final uri = Uri.parse("$baseUrl/$quizId/submit");
    final jsonBody = jsonEncode(requestBody);

    // 👉 Log chi tiết trước khi gửi
    print("📤 [POST QUIZ RESULT]");
    print("➡️ URL: $uri");
    print("➡️ Headers: {Content-Type: application/json}");
    print("➡️ userId: $userId");
    print("➡️ quizId: $quizId");
    print("➡️ durationSeconds: $durationSeconds");
    print("➡️ answers count: ${userAnswers.length}");
    print("➡️ Body JSON: $jsonBody");

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonBody,
    );

    // 👉 Log chi tiết sau khi gửi
    print("📥 [RESPONSE]");
    print("⬅️ Status: ${response.statusCode}");
    print("⬅️ Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return QuizResult.fromJson(data);
    } else {
      throw Exception(
          "Failed to submit quiz. Status: ${response.statusCode}, Body: ${response.body}");
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

}