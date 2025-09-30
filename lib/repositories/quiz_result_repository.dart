import 'dart:convert';
import 'package:http/http.dart' as http;
import 'progress_repository.dart'; // để lấy host & headers

class QuizResultRepository {
  final String baseUrl = "${ProgressRepository.host}/api/quizresults";

  Future<List<dynamic>> getDailyAccuracy(int userId, String fromDateIso) async {
    final uri = Uri.parse("$baseUrl/accuracy/daily")
        .replace(queryParameters: {
      'userId': '$userId',
      'fromDate': fromDateIso,
    });

    final res = await http.get(uri, headers: ProgressRepository.authHeaders(await ProgressRepository.getToken()));
    if (res.statusCode != 200) throw Exception("HTTP ${res.statusCode}: ${res.body}");

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] != true) throw Exception(data['message'] ?? 'Unexpected');

    return (data['data'] as List?) ?? const [];
  }

  Future<List<dynamic>> getDailyAccuracyRange(int userId, String from, String to) async {
    final uri = Uri.parse("$baseUrl/accuracy/daily/range")
        .replace(queryParameters: {'userId': '$userId', 'fromDate': from, 'toDate': to});

    final res = await http.get(uri, headers: ProgressRepository.authHeaders(await ProgressRepository.getToken()));
    if (res.statusCode != 200) throw Exception("HTTP ${res.statusCode}: ${res.body}");

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] != true) throw Exception(data['message'] ?? 'Unexpected');

    return (data['data'] as List?) ?? const [];
  }

  Future<Map<String, dynamic>> getOverallAccuracy(int userId) async {
    final uri = Uri.parse("$baseUrl/accuracy").replace(queryParameters: {'userId': '$userId'});
    final res = await http.get(uri, headers: ProgressRepository.authHeaders(await ProgressRepository.getToken()));

    if (res.statusCode != 200) throw Exception("HTTP ${res.statusCode}: ${res.body}");
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<double> getAverageDailyAccuracy(int userId) async {
    final uri = Uri.parse("$baseUrl/accuracy/daily/average").replace(queryParameters: {'userId': '$userId'});
    final res = await http.get(uri, headers: ProgressRepository.authHeaders(await ProgressRepository.getToken()));
    if (res.statusCode != 200) throw Exception("HTTP ${res.statusCode}: ${res.body}");

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final num? v = (data['data'] is Map) ? (data['data']['averageDailyPercentage'] as num?) : (data['data'] as num?);
    return (v ?? 0).toDouble();
  }
}

// gợi ý: tạo 1 instance dùng chung
final quizResultRepo = QuizResultRepository();
