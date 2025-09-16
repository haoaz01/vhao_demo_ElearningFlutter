import 'package:get/get.dart';
import '../model/quiz_model.dart';
import '../model/question_model.dart';
import '../model/choice_model.dart';
import '../model/quiz_result_model.dart';
import '../repositories/quiz_repository.dart';

class QuizController extends GetxController {
  final QuizRepository repository = QuizRepository();

  var isLoading = false.obs;
  var quizzes = <Quiz>[].obs;

  // Tách riêng quiz theo loại
  var fifteenMinuteQuizzes = <Quiz>[].obs;
  var thirtyMinuteQuizzes = <Quiz>[].obs;

  // Quiz đang chọn
  var selectedQuiz = Rxn<Quiz>();

  // Danh sách câu hỏi + lựa chọn
  var questions = <Question>[].obs;
  var choices = <int, List<Choice>>{}.obs; // questionId -> choices

  // Kết quả quiz cuối cùng
  var lastResult = Rxn<QuizResult>();

  /// Danh sách chapter và quiz set
  var chapters = <Map<String, dynamic>>[].obs;

  /// Lưu kết quả quiz cục bộ (theo chapter + setTitle)
  var quizResults = <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllQuizzes();
  }

  /// Lấy tất cả quiz
  Future<void> fetchAllQuizzes() async {
    try {
      isLoading.value = true;
      final data = await repository.getAllQuizzes();
      quizzes.assignAll(data);

      // Phân loại theo quizTypeId
      fifteenMinuteQuizzes.assignAll(data.where((q) => q.quizTypeId == 1).toList());
      thirtyMinuteQuizzes.assignAll(data.where((q) => q.quizTypeId == 2).toList());
    } catch (e) {
      print("❌ Error fetching quizzes: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Lấy quiz theo id
  Future<void> fetchQuizById(int id) async {
    try {
      isLoading.value = true;
      final quiz = await repository.getQuizById(id);
      selectedQuiz.value = quiz;

      // đồng thời load câu hỏi
      await fetchQuizQuestions(id);
    } catch (e) {
      print("❌ Error fetching quiz: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Lấy quiz theo code
  Future<void> fetchQuizByCode(String code) async {
    try {
      isLoading.value = true;
      final quiz = await repository.getQuizByCode(code);
      selectedQuiz.value = quiz;
      await fetchQuizQuestions(quiz.id);
    } catch (e) {
      print("❌ Error fetching quiz: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Lọc quiz theo grade + subject (+ quizTypeId nếu có)
  Future<void> fetchQuizzesByFilter(int gradeId, int subjectId, {int? quizTypeId}) async {
    try {
      isLoading.value = true;
      final data = await repository.getQuizzesByFilter(gradeId, subjectId, quizTypeId: quizTypeId);
      quizzes.assignAll(data);

      // Phân loại lại
      fifteenMinuteQuizzes.assignAll(data.where((q) => q.quizTypeId == 1).toList());
      thirtyMinuteQuizzes.assignAll(data.where((q) => q.quizTypeId == 2).toList());
    } catch (e) {
      print("❌ Error fetching quizzes by filter: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Lấy danh sách câu hỏi của quiz
  Future<void> fetchQuizQuestions(int quizId) async {
    try {
      final data = await repository.getQuizQuestions(quizId);
      questions.assignAll(data);

      // load luôn choices cho từng câu hỏi
      for (var q in data) {
        final ch = await repository.getQuestionChoices(q.id);
        choices[q.id] = ch;
      }
    } catch (e) {
      print("❌ Error fetching quiz questions: $e");
    }
  }

  /// Nộp quiz và lưu kết quả
  Future<void> submitQuiz(int quizId, int userId, Map<int, int> userAnswers) async {
    try {
      final result = await repository.submitQuiz(quizId, userId, userAnswers);
      lastResult.value = result;
      print("✅ Quiz submitted. Score: ${result.score}");
    } catch (e) {
      print("❌ Error submitting quiz: $e");
    }
  }

  /// Lấy thống kê quiz
  Future<Map<String, dynamic>> getQuizStatistics(int quizId) async {
    return await repository.getQuizStatistics(quizId);
  }

  /// Load quiz theo subject & grade
  Future<void> loadQuiz(String subject, int grade) async {
    try {
      isLoading.value = true;

      // Chuyển đổi tên môn học thành ID
      int subjectId = _convertSubjectToId(subject);
      print('Loading quiz for subject: $subject (ID: $subjectId), grade: $grade');

      final data = await repository.getQuizzesBySubjectAndGrade(grade, subjectId);

      if (data == null || data.isEmpty) {
        print('No quizzes found for the given criteria');
        chapters.value = [];
        Get.snackbar("Thông báo", "Không có quiz nào cho môn học này");
        return;
      }

      // Group theo chapter_title
      Map<String, List<Quiz>> chapterMap = {};

      for (var quiz in data) {
        String chapterName = quiz.chapterTitle ?? "Chương không xác định";

        if (!chapterMap.containsKey(chapterName)) {
          chapterMap[chapterName] = [];
        }
        chapterMap[chapterName]!.add(quiz);
      }

      // Chuyển thành list chapters
      chapters.value = chapterMap.entries.map((entry) {
        return {
          "chapter": entry.key,
          "sets": entry.value.map((quiz) {
            return {
              "title": quiz.code ?? "No Title",
              "questions": quiz.questions ?? [],
              "quiz": quiz,
            };
          }).toList(),
        };
      }).toList();

      print('✅ Successfully loaded ${chapters.length} chapters');
    } catch (e) {
      print('❌ Error loading quiz: $e');
      Get.snackbar("Lỗi", "Không tải được quiz: ${e.toString()}");
      chapters.value = [];
    } finally {
      isLoading.value = false;
    }
    update();
  }

  /// Cập nhật kết quả quiz khi nộp bài (lưu cục bộ)
  void updateResult(String chapterName, String setTitle, int score, int correct) {
    quizResults["$chapterName-$setTitle"] = {
      "score": score,
      "correct": correct,
      "completed": true,
    };
    update();
  }

  /// Gửi kết quả quiz về backend
  Future<void> postQuizResult({
    required String chapterName,
    required String setTitle,
    required int score,
    required int correct,
    required int total,
    required int quizTypeId,
    required Map<int, int> userAnswers,
  }) async {
    try {
      Quiz? foundQuiz;
      for (var chapter in chapters) {
        if (chapter["chapter"] == chapterName) {
          for (var set in chapter["sets"]) {
            if (set["title"] == setTitle) {
              foundQuiz = set["quiz"];
              break;
            }
          }
        }
        if (foundQuiz != null) break;
      }

      if (foundQuiz != null && foundQuiz.id != null) {
        // TODO: Replace with actual user ID from authentication
        const int userId = 1; // Hardcoded for now
        final result = await repository.submitQuiz(foundQuiz.id!, userId, userAnswers);
        lastResult.value = result;
        update();
      }
    } catch (e) {
      print("❌ Error posting quiz result: $e");
      rethrow; // Re-throw the error to handle it in the UI
    }
  }

  /// Lấy điểm theo chapter + setTitle
  int getScore(String chapterName, String setTitle) {
    return quizResults["$chapterName-$setTitle"]?["score"] ?? 0;
  }

  /// Lấy số câu đúng
  int getCorrectAnswers(String chapterName, String setTitle) {
    return quizResults["$chapterName-$setTitle"]?["correct"] ?? 0;
  }

  /// Kiểm tra đã hoàn thành quiz chưa
  bool isCompleted(String chapterName, String setTitle) {
    return quizResults["$chapterName-$setTitle"]?["completed"] ?? false;
  }

  /// Chuyển đổi tên môn học thành ID
  int _convertSubjectToId(String subject) {
    switch (subject.toLowerCase()) {
      case 'toan':
        return 1;
      case 'nguvan':
        return 2;
      case 'tienganh':
        return 3;
      case 'khoahoctunhien':
        return 4;
      default:
        return 1;
    }
  }
}
