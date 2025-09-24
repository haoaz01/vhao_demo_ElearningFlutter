import 'package:get/get.dart';
import '../model/quiz_history_model.dart';
import '../model/quiz_model.dart';
import '../model/question_model.dart';
import '../model/choice_model.dart';
import '../model/quiz_result_model.dart';
import '../repositories/quiz_repository.dart';
import 'auth_controller.dart';
import 'package:flutter/material.dart';

class QuizController extends GetxController {
  final QuizRepository quizRepository = QuizRepository();

  var isLoading = false.obs;
  var quizzes = <Quiz>[].obs;
  var fifteenMinuteQuizzes = <Quiz>[].obs;
  var thirtyMinuteQuizzes = <Quiz>[].obs;
  var selectedQuiz = Rxn<Quiz>();
  var questions = <Question>[].obs;
  var choices = <int, List<Choice>>{}.obs;
  var lastResult = Rxn<QuizResult>();
  var chapters = <Map<String, dynamic>>[].obs;
  var quizResults = <String, Map<String, dynamic>>{}.obs;
  var quizHistory = <QuizHistory>[].obs;
  var isHistoryLoading = false.obs;

  /// Subject mapping theo grade
  final subjectMapping = <int, List<Map<String, dynamic>>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllQuizzes();
  }

  Future<void> fetchAllQuizzes() async {
    try {
      isLoading.value = true;
      final data = await quizRepository.getAllQuizzes();
      quizzes.assignAll(data);
      fifteenMinuteQuizzes.assignAll(data.where((q) => q.quizTypeId == 1).toList());
      thirtyMinuteQuizzes.assignAll(data.where((q) => q.quizTypeId == 2).toList());
    } catch (e) {
      print("❌ Error fetching quizzes: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchQuizById(int id) async {
    try {
      isLoading.value = true;
      final quiz = await quizRepository.getQuizById(id);
      selectedQuiz.value = quiz;
      await fetchQuizQuestions(id);
    } catch (e) {
      print("❌ Error fetching quiz: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchQuizByCode(String code) async {
    try {
      isLoading.value = true;
      final quiz = await quizRepository.getQuizByCode(code);
      selectedQuiz.value = quiz;
      await fetchQuizQuestions(quiz.id);
    } catch (e) {
      print("❌ Error fetching quiz: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchQuizzesByFilter(int gradeId, int subjectId, {int? quizTypeId}) async {
    try {
      isLoading.value = true;
      final data = await quizRepository.getQuizzesByFilter(gradeId, subjectId, quizTypeId: quizTypeId);
      quizzes.assignAll(data);
      fifteenMinuteQuizzes.assignAll(data.where((q) => q.quizTypeId == 1).toList());
      thirtyMinuteQuizzes.assignAll(data.where((q) => q.quizTypeId == 2).toList());
    } catch (e) {
      print("❌ Error fetching quizzes by filter: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchQuizQuestions(int quizId) async {
    try {
      final data = await quizRepository.getQuizQuestions(quizId);
      questions.assignAll(data);

      for (var q in data) {
        final ch = await quizRepository.getQuestionChoices(q.id);
        choices[q.id] = ch;
      }
    } catch (e) {
      print("❌ Error fetching quiz questions: $e");
    }
  }

  Future<QuizResult> submitQuiz(int quizId, Map<int, List<int>> userAnswers, int durationSeconds) async {
    try {
      final result = await quizRepository.submitQuiz(quizId, userAnswers, durationSeconds);
      lastResult.value = result;
      return result;
    } catch (e) {
      print("❌ Error submitting quiz: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getQuizStatistics(int quizId) async {
    return await quizRepository.getQuizStatistics(quizId);
  }

  Future<void> loadQuiz(String subject, int grade) async {
    try {
      isLoading.value = true;

      // 🔹 Lấy subjectId động từ API
      final subjectId = await _getSubjectIdByGradeAndName(grade, subject);

      if (subjectId == null) {
        Get.snackbar("Thông báo", "Không tìm thấy môn $subject cho lớp $grade");
        chapters.value = [];
        return;
      }

      final data = await quizRepository.getQuizzesBySubjectAndGrade(grade, subjectId);

      if (data.isEmpty) {
        chapters.value = [];
        Get.snackbar("Thông báo", "Không có quiz nào cho môn học này");
        return;
      }

      Map<String, List<Quiz>> chapterMap = {};
      for (var quiz in data) {
        String chapterName = quiz.chapterTitle ?? "Chương không xác định";
        chapterMap.putIfAbsent(chapterName, () => []);
        chapterMap[chapterName]!.add(quiz);
      }

      chapters.value = chapterMap.entries.map((entry) {
        return {
          "chapter": entry.key,
          "sets": entry.value.map((quiz) {
            return {
              "title": quiz.code,
              "questions": quiz.questions,
              "quiz": quiz,
            };
          }).toList(),
        };
      }).toList();
    } catch (e) {
      Get.snackbar("Lỗi", "Không tải được quiz: ${e.toString()}");
      chapters.value = [];
    } finally {
      isLoading.value = false;
    }
    update();
  }

  void updateResult(String chapterName, String setTitle, int score, int correct) {
    quizResults["$chapterName-$setTitle"] = {
      "score": score,
      "correct": correct,
      "completed": true,
    };
    update();
  }

  int getScore(String chapterName, String setTitle) {
    return quizResults["$chapterName-$setTitle"]?["score"] ?? 0;
  }

  int getCorrectAnswers(String chapterName, String setTitle) {
    return quizResults["$chapterName-$setTitle"]?["correct"] ?? 0;
  }

  bool isCompleted(String chapterName, String setTitle) {
    return quizResults["$chapterName-$setTitle"]?["completed"] ?? false;
  }

  Future<void> fetchQuizHistory(int quizId) async {
    try {
      isHistoryLoading.value = true;

      final authController = Get.find<AuthController>();
      final userId = authController.userId.value;

      if (userId == 0) {
        throw Exception("User not logged in");
      }

      final history = await quizRepository.getQuizHistory(quizId, userId);
      quizHistory.assignAll(history);
    } catch (e) {
      Get.snackbar(
        "Lỗi",
        "Không thể tải lịch sử làm bài: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isHistoryLoading.value = false;
    }
  }

  /// 🔹 Tìm subjectId dựa vào grade + subjectName
  Future<int?> _getSubjectIdByGradeAndName(int gradeId, String subjectName) async {
    // Nếu chưa cache → gọi API
    if (!subjectMapping.containsKey(gradeId)) {
      final subjects = await quizRepository.getSubjectsByGrade(gradeId);
      subjectMapping[gradeId] = subjects;
    }

    final subjects = subjectMapping[gradeId]!;
    final subject = subjects.firstWhereOrNull(
          (s) => (s['name'] as String).toLowerCase() == subjectName.toLowerCase(),
    );

    return subject?['id'];
  }
}
