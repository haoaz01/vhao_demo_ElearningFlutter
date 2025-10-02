import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/daily_quiz_stat_model.dart';
import '../model/quiz_attempt_model.dart';
import '../model/quiz_history_model.dart';
import '../repositories/quiz_result_repository.dart';

class QuizHistoryController extends GetxController {
  final quizDaily = <QuizDailyStat>[].obs;
  final isQuizLoading = false.obs;
  var history = <QuizHistory>[].obs;

  final isLoadingHistory = false.obs;
  // final history = <QuizAttempt>[].obs;

  Future<int> _uid() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt('userId') ?? 0;
  }

  Future<void> loadDailyStats({int days = 7}) async {
    isQuizLoading.value = true;
    try {
      final userId = await _uid();
      if (userId == 0) { quizDaily.clear(); return; }

      final fromDate = DateTime.now().subtract(Duration(days: days));
      final fromIso = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(fromDate);

      final raw = await quizResultRepo.getDailyAccuracy(userId, fromIso);
      final parsed = raw.map((e) => QuizDailyStat.fromJson(e as Map<String,dynamic>)).toList();

      // Map theo key ngày có sẵn từ API
      final byDay = { for (final e in parsed) e.dayKey : e };

      // Fill đủ N ngày gần nhất (kể cả ngày không có dữ liệu -> % = 0)
      final filled = <QuizDailyStat>[];
      for (int i = 0; i < days; i++) {
        final d = DateTime.now().subtract(Duration(days: days - 1 - i));
        final key = DateFormat('yyyy-MM-dd').format(d);
        filled.add(
          byDay[key] ??
              QuizDailyStat(day: d, percentAccuracy: 0, correctSum: 0, totalSum: 0),
        );
      }
      quizDaily.assignAll(filled);
    } catch (e) {
      // print('loadDailyStats error: $e');
      quizDaily.clear();
    } finally {
      isQuizLoading.value = false;
    }
  }

}
