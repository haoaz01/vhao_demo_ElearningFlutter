import 'dart:convert';
import 'package:http/http.dart' as http;
import 'progress_repository.dart';

class QuizHistoryRepository {
  static String get _base => '${ProgressRepository.host}/api';

  static Future<Map<String, dynamic>?> getBestScore(int quizId, int userId, {String? token}) async {
    final res = await http.get(
      Uri.parse('$_base/quizzes/$quizId/users/$userId/best-score'),
      headers: {'Accept': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 404) return null; // không có lịch sử -> null
    throw Exception('best-score error ${res.statusCode}');
  }

  // daily stats (nếu backend đã có). Nếu chưa có, controller sẽ tự tính fallback.
  static Future<List<dynamic>> getDailyStats(int userId, int days, {String? token}) async {
    final url = Uri.parse('$_base/quiz-results/users/$userId/daily?days=$days');
    final res = await http.get(url, headers: {'Accept':'application/json', if (token != null) 'Authorization':'Bearer $token'});
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    if (res.statusCode == 404) return <dynamic>[];
    throw Exception('daily-stats error ${res.statusCode}');
  }
}
