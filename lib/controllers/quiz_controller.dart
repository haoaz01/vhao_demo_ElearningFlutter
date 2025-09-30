import 'package:flutter_elearning_application/controllers/progress_controller.dart';
import 'package:flutter_elearning_application/controllers/quiz_history_controller.dart';
import 'package:get/get.dart';
import '../model/quiz_history_model.dart';
import '../controllers/quiz_history_controller.dart';
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
  // var quizHistory = <QuizHistory>[].obs;
  var isHistoryLoading = false.obs;
  var bestScore = <String, Map<String, dynamic>>{}.obs;
  var isBestScoreLoading = false.obs;

  /// Subject mapping theo grade
  final subjectMapping = <int, List<Map<String, dynamic>>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Get.put(QuizController());
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
      // 🔥 KIỂM TRA TRẠNG THÁI ĐĂNG NHẬP TRƯỚC KHI GỬI REQUEST
      final authController = Get.find<AuthController>();
      authController.checkAuthStatus();

      if (!authController.isLoggedIn.value || authController.authToken.value.isEmpty) {
        throw Exception("User not authenticated. Please login again.");
      }

      final result = await quizRepository.submitQuiz(quizId, userAnswers, durationSeconds);
      Get.find<QuizHistoryController>().loadDailyStats(days: 7);
      lastResult.value = result;

      print("✅ Quiz submitted successfully: ${result.score}");
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

      // 🔹 TỰ ĐỘNG LOAD BEST SCORES CHO TẤT CẢ QUIZ
      final authController = Get.find<AuthController>();
      final userId = authController.userId.value;

      if (userId > 0) {
        // Lấy tất cả quizIds từ chapters
        List<int> quizIds = [];
        for (var chapter in chapters) {
          for (var set in chapter["sets"]) {
            quizIds.add(set["quiz"].id);
          }
        }

        // Load best scores cho tất cả quiz (song song)
        await Future.wait(
            quizIds.map((quizId) => fetchBestScoreForUser(quizId, userId))
        );
      }

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

  // Future<void> fetchQuizHistory(int quizId) async {
  //   try {
  //     isHistoryLoading.value = true;
  //
  //     final authController = Get.find<AuthController>();
  //     final userId = authController.userId.value;
  //
  //     if (userId == 0) {
  //       throw Exception("User not logged in");
  //     }
  //
  //     final history = await quizRepository.getQuizHistory(quizId, userId);
  //     quizHistory.assignAll(history);
  //   } catch (e) {
  //     Get.snackbar(
  //       "Lỗi",
  //       "Không thể tải lịch sử làm bài: ${e.toString()}",
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: Colors.red,
  //       colorText: Colors.white,
  //     );
  //   } finally {
  //     isHistoryLoading.value = false;
  //   }
  // }

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

  Future<void> fetchBestScoreForUser(int quizId, int userId) async {
    try {
      isBestScoreLoading.value = true;

      final data = await quizRepository.getBestScoreForUser(quizId, userId);

      if (data.isNotEmpty) {
        bestScore["$quizId-$userId"] = data;
      } else {
        bestScore.remove("$quizId-$userId");
      }
    } catch (e) {
      print("❌ Error fetching best score: $e");
      Get.snackbar(
        "Lỗi",
        "Không thể tải điểm cao nhất",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isBestScoreLoading.value = false;
    }
  }

  /// 🔹 NEW: Lấy điểm cao nhất (auto-detect userId từ AuthController)
  Future<void> fetchBestScore(int quizId) async {
    final authController = Get.find<AuthController>();
    final userId = authController.userId.value;

    if (userId == 0) {
      throw Exception("User not logged in");
    }

    await fetchBestScoreForUser(quizId, userId);
  }

  /// 🔹 NEW: Kiểm tra xem đã có best score chưa
  bool hasBestScore(int quizId, int userId) {
    return bestScore.containsKey("$quizId-$userId");
  }

  /// 🔹 NEW: Lấy best score dưới dạng số
  double getBestScoreValue(int quizId, int userId) {
    final data = bestScore["$quizId-$userId"];
    if (data != null && data.containsKey('bestScore')) {
      return (data['bestScore'] as num).toDouble();
    }
    return 0.0;
  }

  /// 🔹 NEW: Lấy số câu đúng cao nhất
  int getBestCorrectAnswers(int quizId, int userId) {
    final data = bestScore["$quizId-$userId"];
    if (data != null && data.containsKey('bestCorrectAnswers')) {
      return data['bestCorrectAnswers'] as int;
    }
    return 0;
  }

  /// 🔹 NEW: Kiểm tra đã vượt qua quiz chưa (điểm >= 5.0)
  bool isQuizPassed(int quizId, int userId) {
    final data = bestScore["$quizId-$userId"];
    if (data != null && data.containsKey('passed')) {
      return data['passed'] as bool;
    }
    return false;
  }

  /// 🔹 NEW: Cập nhật best score sau khi submit quiz thành công
  void updateBestScoreAfterSubmit(int quizId, int userId, double newScore, int newCorrectAnswers) {
    final currentBestScore = getBestScoreValue(quizId, userId);
    final currentBestCorrect = getBestCorrectAnswers(quizId, userId);

    // Nếu điểm mới cao hơn, hoặc bằng điểm nhưng số câu đúng cao hơn
    if (newScore > currentBestScore ||
        (newScore == currentBestScore && newCorrectAnswers > currentBestCorrect)) {

      bestScore["$quizId-$userId"] = {
        'bestScore': newScore,
        'bestCorrectAnswers': newCorrectAnswers,
        'passed': newScore >= 5.0,
        'updatedAt': DateTime.now().toString(),
      };
    }
  }

  /// 🔹 Lấy best score cho một quiz cụ thể (auto-detect user)
  Future<void> loadBestScoreForQuiz(int quizId) async {
    final authController = Get.find<AuthController>();
    final userId = authController.userId.value;

    if (userId > 0) {
      await fetchBestScoreForUser(quizId, userId);
    }
  }

  /// 🔹 Kiểm tra xem quiz có best score không
  bool hasBestScoreForQuiz(int quizId) {
    final authController = Get.find<AuthController>();
    final userId = authController.userId.value;
    return userId > 0 && hasBestScore(quizId, userId);
  }

  /// 🔹 Lấy giá trị best score
  double getBestScoreForQuiz(int quizId) {
    final authController = Get.find<AuthController>();
    final userId = authController.userId.value;
    return userId > 0 ? getBestScoreValue(quizId, userId) : 0.0;
  }

  /// 🔹 Lấy số câu đúng cao nhất
  int getBestCorrectForQuiz(int quizId) {
    final authController = Get.find<AuthController>();
    final userId = authController.userId.value;
    return userId > 0 ? getBestCorrectAnswers(quizId, userId) : 0;
  }

  /// 🔹 Kiểm tra đã vượt qua quiz
  bool isQuizPassedBest(int quizId) {
    final authController = Get.find<AuthController>();
    final userId = authController.userId.value;
    return userId > 0 ? isQuizPassed(quizId, userId) : false;
  }
}
