import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/quiz_attempt_model.dart';
import 'progress_repository.dart';

/// Repo duy nhất cho lịch sử quiz.
/// - Ưu tiên endpoint:   GET /api/quizzes/{quizId}/results?userId={userId}
/// - Fallback endpoint:  GET /api/quizresults/quiz/{quizId}/history?userId={userId}
class QuizHistoryRepository {
  QuizHistoryRepository._();

  /// Lấy danh sách lịch sử attempt (raw json list)
  static Future<List<dynamic>> getHistory(int quizId, int userId) async {
    final token   = await ProgressRepository.getToken();
    final headers = ProgressRepository.authHeaders(token);

    // 1) Endpoint ưu tiên (theo cấu trúc /api/quizzes)
    final urlA = Uri.parse(
      '${ProgressRepository.quizzesBase}/$quizId/results?userId=$userId',
    );

    try {
      final res = await http.get(urlA, headers: headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          return (body['data'] as List?) ?? <dynamic>[];
        }
        if (body is List) return body;
        return <dynamic>[];
      }
    } catch (_) {
      // im lặng, thử endpoint B
    }

    // 2) Fallback endpoint (theo cấu trúc /api/quizresults)
    final urlB = Uri.parse(
      '${ProgressRepository.host}/api/quizresults/quiz/$quizId/history?userId=$userId',
    );

    final resB = await http.get(urlB, headers: headers);
    if (resB.statusCode == 200) {
      final body = jsonDecode(resB.body);
      if (body is Map && body['success'] == true) {
        return (body['data'] as List?) ?? <dynamic>[];
      }
      if (body is List) return body;
      return <dynamic>[];
    }

    if (resB.statusCode == 404) return <dynamic>[];
    throw Exception('Load history failed: ${resB.statusCode} ${resB.body}');
  }

  /// Trả về danh sách `QuizAttempt` đã parse sẵn
  static Future<List<QuizAttempt>> getAttempts(int quizId, int userId) async {
    final raw = await getHistory(quizId, userId);

    // Tùy backend trả snake_case hay camelCase → fromJson cần map đúng key
    final attempts = <QuizAttempt>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        try {
          attempts.add(QuizAttempt.fromJson(e));
        } catch (_) {
          // nếu fromJson chuẩn không khớp key, thử fromBestScoreJson (1 số BE dùng)
          try {
            attempts.add(QuizAttempt.fromBestScoreJson(e));
          } catch (_) {
            // bỏ qua record lỗi parse
          }
        }
      }
    }
    return attempts;
  }

  /// Điểm cao nhất (nếu bạn còn dùng chỗ này)
  static Future<Map<String, dynamic>?> getBestScore(
      int quizId,
      int userId, {
        String? token,
      }) async {
    final headers = ProgressRepository.authHeaders(token);
    final url = Uri.parse(
      '${ProgressRepository.host}/api/quizzes/$quizId/users/$userId/best-score',
    );

    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return (body is Map && body['success'] == true)
          ? body['data'] as Map<String, dynamic>?
          : body as Map<String, dynamic>?;
    }
    if (res.statusCode == 404) return null;
    throw Exception('best-score error ${res.statusCode}');
  }

  /// Daily stats (nếu backend đã có), không bắt buộc
  static Future<List<dynamic>> getDailyStats(int userId, int days) async {
    final token   = await ProgressRepository.getToken();
    final headers = ProgressRepository.authHeaders(token);
    final url = Uri.parse(
      '${ProgressRepository.host}/api/quiz-results/users/$userId/daily?days=$days',
    );

    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is Map && body['success'] == true) {
        return (body['data'] as List?) ?? <dynamic>[];
      }
      if (body is List) return body;
      return <dynamic>[];
    }
    if (res.statusCode == 404) return <dynamic>[];
    throw Exception('daily-stats error ${res.statusCode}');
  }
}
