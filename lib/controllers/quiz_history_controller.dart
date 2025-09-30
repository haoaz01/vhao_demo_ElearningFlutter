import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/quiz_attempt.dart';
import '../model/daily_quiz_stat.dart';
import '../repositories/quiz_history_repository.dart';
import '../repositories/progress_repository.dart';

class QuizHistoryController extends GetxController {
  // cho Dashboard chart
  final RxBool isQuizLoading = false.obs;
  final RxList<DailyQuizStat> quizDaily = <DailyQuizStat>[].obs;

  // cho QuizHistoryScreen
  final RxBool isLoadingHistory = false.obs;
  final RxList<QuizAttempt> history = <QuizAttempt>[].obs;

  Future<int> _uid() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt('userId') ?? 0;
    // token nếu cần: sp.getString('authToken')
  }

    Future<void> loadDailyStats({int days = 7}) async {
      try {
        isQuizLoading.value = true;
        final uid = await _uid();
        if (uid == 0) { quizDaily.clear(); return; }

        final raw = await QuizHistoryRepository.getDailyStats(uid, days);
        if (raw.isEmpty) { quizDaily.clear(); return; }

        final parsed = raw.map((e) => DailyQuizStat.fromJson(e as Map<String, dynamic>)).toList();
        // đảm bảo theo thứ tự ngày tăng dần
        parsed.sort((a,b)=>a.day.compareTo(b.day));
        quizDaily.assignAll(parsed);
      } catch (_) {
        quizDaily.clear(); // không crash UI
      } finally {
        isQuizLoading.value = false;
      }
    }
    

  Future<void> fetchQuizHistory(int quizId) async {
    try {
      isLoadingHistory.value = true;
      final uid = await _uid();
      if (uid == 0) { history.clear(); return; }

      // Backend hiện có endpoint best-score; những quiz không có lịch sử trả 404 -> null
      final j = await QuizHistoryRepository.getBestScore(quizId, uid);
      if (j == null) {
        history.clear();
        return;
      }
      history.assignAll([QuizAttempt.fromBestScoreJson(j)]);
    } catch (_) {
      history.clear();
    } finally {
      isLoadingHistory.value = false;
    }
  }
}
