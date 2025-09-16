import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/quiz_model.dart';
import '../model/question_model.dart';
import '../model/choice_model.dart';
import '../model/quiz_result_model.dart';

class QuizRepository {
  final String baseUrl = "http://192.168.0.144:8080/api/quizzes";

  /// Lấy tất cả quizzes
  Future<List<Quiz>> getAllQuizzes() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Quiz.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load quizzes");
    }
  }

  /// Lấy quiz theo id
  Future<Quiz> getQuizById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return Quiz.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Quiz not found");
    }
  }

  /// Lấy quiz theo code
  Future<Quiz> getQuizByCode(String code) async {
    final response = await http.get(Uri.parse("$baseUrl/code/$code"));
    if (response.statusCode == 200) {
      return Quiz.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Quiz not found");
    }
  }

  /// Lọc quiz theo gradeId và subjectId
  Future<List<Quiz>> getQuizzesBySubjectAndGrade(int gradeId, int subjectId) async {
    final queryParams = {
      "gradeId": gradeId.toString(),
      "subjectId": subjectId.toString(),
    };

    try {
      final uri = Uri.parse("$baseUrl/filter").replace(queryParameters: queryParams);
      print("Request URL: ${uri.toString()}");

      final response = await http.get(uri);
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Quiz.fromJson(json)).toList();
      } else {
        print("Request failed with status: ${response.statusCode}");
        throw Exception("Failed to filter quizzes by subject and grade. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Request error: $e");
      rethrow;
    }
  }

  /// Lọc quiz theo gradeId, subjectId, quizTypeId (tùy chọn)
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

  /// Lấy danh sách câu hỏi trong quiz
  Future<List<Question>> getQuizQuestions(int quizId) async {
    final response = await http.get(Uri.parse("$baseUrl/$quizId/questions"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Question.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load quiz questions");
    }
  }

  /// Lấy danh sách lựa chọn trong 1 câu hỏi
  Future<List<Choice>> getQuestionChoices(int questionId) async {
    final response = await http.get(Uri.parse("$baseUrl/questions/$questionId/choices"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Choice.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load choices");
    }
  }

  /// Nộp bài quiz
  Future<QuizResult> submitQuiz(int quizId, int userId, Map<int, int> userAnswers) async {
    final uri = Uri.parse("$baseUrl/$quizId/submit?userId=$userId");

    // Convert integer keys to string keys
    Map<String, int> stringKeyMap = {};
    userAnswers.forEach((key, value) {
      stringKeyMap[key.toString()] = value;
    });

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(stringKeyMap),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['quizResult'] != null) {
        return QuizResult.fromJson(data['quizResult']);
      } else {
        return QuizResult(
          id: 0,
          quizId: quizId,
          userId: userId,
          score: data['score']?.toDouble() ?? 0.0,
          correctAnswers: data['correctAnswers'] ?? 0,
          totalQuestions: data['totalQuestions'] ?? 0,
          createdAt: DateTime.now(),
        );
      }
    } else {
      throw Exception("Failed to submit quiz. Status: ${response.statusCode}");
    }
  }


  /// Thống kê quiz
  Future<Map<String, dynamic>> getQuizStatistics(int quizId) async {
    final response = await http.get(Uri.parse("$baseUrl/$quizId/statistics"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load statistics");
    }
  }
}