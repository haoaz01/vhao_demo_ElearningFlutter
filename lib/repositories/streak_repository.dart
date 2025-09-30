// lib/repositories/streak_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'progress_repository.dart';

class UserStreak {
  final int current;
  final int best;
  final int total;
  final DateTime? lastCheckIn;
  UserStreak({required this.current, required this.best, required this.total, this.lastCheckIn});

  factory UserStreak.fromJson(Map<String, dynamic> j) => UserStreak(
    current: (j['currentStreak'] ?? 0) as int,
    best:    (j['bestStreak']    ?? 0) as int,
    total:   (j['totalDays']     ?? 0) as int,
    lastCheckIn: j['lastActiveDate'] != null
        ? DateTime.tryParse(j['lastActiveDate'].toString())
        : null,
  );
}

class StreakRepository {
  static String get _base => ProgressRepository.streakBase;

  static Future<UserStreak> getStreak(int userId) async {
    final token = await ProgressRepository.getToken();
    final res = await http.get(
      Uri.parse('$_base/$userId'),
      headers: ProgressRepository.authHeaders(token),
    );
    if (res.statusCode == 200) {
      return UserStreak.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    if (res.statusCode == 404) {
      return UserStreak(current: 0, best: 0, total: 0, lastCheckIn: null);
    }
    throw Exception('getStreak failed ${res.statusCode}: ${res.body}');
  }

  static Future<UserStreak> touch(int userId) async {
    final token = await ProgressRepository.getToken();
    final res = await http.post(
      Uri.parse('$_base/$userId/touch'),
      headers: ProgressRepository.authHeaders(token),
    );
    if (res.statusCode == 200) {
      return UserStreak.fromJson(jsonDecode(res.body));
    }
    throw Exception('touch failed ${res.statusCode}: ${res.body}');
  }

  static Future<UserStreak> checkInToday(int userId) async {
    final token = await ProgressRepository.getToken();
    final res = await http.post(
      Uri.parse('$_base/$userId/online'),
      headers: ProgressRepository.authHeaders(token),
    );
    if (res.statusCode == 200) {
      print("✅ Check-in thành công: ${res.body}");
      return UserStreak.fromJson(jsonDecode(res.body));
    }
    throw Exception('online failed ${res.statusCode}: ${res.body}');
  }
}

