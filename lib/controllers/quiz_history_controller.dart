import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/daily_quiz_stat.dart';
import '../model/quiz_attempt.dart';
import '../repositories/quiz_result_repository.dart';
import '../repositories/quiz_history_repository.dart';

class QuizHistoryController extends GetxController {
  // === Cho Dashboard chart ===
  final quizDaily = <QuizDailyStat>[].obs;
  final isQuizLoading = false.obs;

  // === Cho QuizHistoryScreen ===
  final isLoadingHistory = false.obs;
  final history = <QuizAttempt>[].obs;

  Future<int> _uid() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt('userId') ?? 0;
  }

  /// load dữ liệu cho biểu đồ quiz trong Dashboard
  Future<void> loadDailyStats({int days = 7}) async {
    isQuizLoading.value = true;
    try {
      final userId = await _uid();
      if (userId == 0) {
        quizDaily.clear();
        return;
      }

      final fromDate = DateTime.now().subtract(Duration(days: days));
      final iso = fromDate.toIso8601String();

      final raw = await quizResultRepo.getDailyAccuracy(userId, iso);

      final parsed = <QuizDailyStat>[];
      for (final e in raw) {
        try {
          parsed.add(QuizDailyStat.fromJson(e as Map<String, dynamic>));
        } catch (_) {}
      }

      quizDaily.assignAll(parsed);
    } catch (e) {
      print('loadDailyStats error: $e');
      quizDaily.clear();
    } finally {
      isQuizLoading.value = false;
    }
  }

  /// load lịch sử 1 quiz cụ thể cho QuizHistoryScreen
  Future<void> fetchQuizHistory(int quizId) async {
    try {
      isLoadingHistory.value = true;
      final uid = await _uid();
      if (uid == 0) {
        history.clear();
        return;
      }

      final j = await QuizHistoryRepository.getBestScore(quizId, uid);
      if (j == null) {
        history.clear();
        return;
      }

      history.assignAll([QuizAttempt.fromBestScoreJson(j)]);
    } catch (e) {
      history.clear();
    } finally {
      isLoadingHistory.value = false;
    }
  }
}
