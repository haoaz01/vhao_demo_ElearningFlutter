// lib/repositories/streak_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'progress_repository.dart';
import '../model/calendar_day.dart';

/// ===== Models =====

class StreakData {
  final int currentStreak;
  final int? bestStreak;
  final int? totalDays;
  final DateTime? streakStartDate;
  final DateTime? streakEndDate;
  final int? todayMinutes;
  final bool? todayStudied;
  final List<CalendarDay> calendarDays;

  StreakData({
    required this.currentStreak,
    this.bestStreak,
    this.totalDays,
    this.streakStartDate,
    this.streakEndDate,
    this.todayMinutes,
    this.todayStudied,
    this.calendarDays = const [],
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    final src = (json['data'] is Map<String, dynamic>) ? json['data'] : json;

    // Parse dates
    final startRaw = src['streakStartDate'] ?? src['startDate'];
    final endRaw = src['streakEndDate'] ?? src['lastActiveDate'] ?? src['endDate'];

    // Parse calendar days - DÙNG CalendarDay từ model chung
    List<CalendarDay> calendarDays = [];
    if (src['calendarDays'] is List) {
      calendarDays = (src['calendarDays'] as List)
          .map((day) => CalendarDay.fromJson(day))
          .toList();
    }

    // Calculate today's data from calendar
    final today = DateTime.now();
    final todayData = calendarDays.firstWhere(
          (day) => _isSameDay(day.date, today),
      orElse: () => CalendarDay(
        date: today,
        studied: false,
        minutesStudied: 0,
        isInCurrentStreak: false,
      ),
    );

    return StreakData(
      currentStreak: (src['currentStreak'] ?? src['current'] ?? 0) as int,
      bestStreak: (src['bestStreak'] ?? src['best'] ?? 0) as int,
      totalDays: (src['totalDays'] ?? src['total'] ?? 0) as int,
      streakStartDate: startRaw != null ? DateTime.tryParse(startRaw.toString()) : null,
      streakEndDate: endRaw != null ? DateTime.tryParse(endRaw.toString()) : null,
      todayMinutes: src['todayMinutes'] as int?,
      todayStudied: (src['todayStudied'] ?? src['isStudiedDay']) as bool?,
      calendarDays: calendarDays,
    );
  }

  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}


class RecordActivityResult {
  final bool saved;
  final int newTotalMinutes;
  final bool statusChanged;
  final bool isStudiedDay;
  final int previousTotalMinutes;
  final int additionalMinutes;

  RecordActivityResult({
    required this.saved,
    required this.newTotalMinutes,
    required this.statusChanged,
    required this.isStudiedDay,
    required this.previousTotalMinutes,
    required this.additionalMinutes,
  });

  factory RecordActivityResult.fromJson(Map<String, dynamic> json) {
    final src = (json['data'] is Map<String, dynamic>) ? json['data'] : json;
    return RecordActivityResult(
      saved: (src['saved'] ?? json['success'] ?? true) as bool,
      newTotalMinutes: (src['newTotalMinutes'] ?? src['minutesUsed'] ?? 0) as int,
      statusChanged: (src['statusChanged'] ?? src['changed'] ?? false) as bool,
      isStudiedDay: (src['isStudiedDay'] ?? src['studied'] ?? false) as bool,
      previousTotalMinutes: (src['previousTotalMinutes'] ?? 0) as int,
      additionalMinutes: (src['additionalMinutes'] ?? 0) as int,
    );
  }
}

class TodayStatus {
  final int totalMinutes;
  final bool isStudiedDay;
  final bool hasActivity;

  TodayStatus({
    required this.totalMinutes,
    required this.isStudiedDay,
    required this.hasActivity,
  });

  factory TodayStatus.fromJson(Map<String, dynamic> json) {
    final src = (json['data'] is Map<String, dynamic>) ? json['data'] : json;
    return TodayStatus(
      totalMinutes: (src['totalMinutes'] ?? src['minutesUsed'] ?? 0) as int,
      isStudiedDay: (json['isStudiedDay'] ?? src['isStudiedDay'] ?? false) as bool,
      hasActivity: (src['hasActivity'] ?? (src['totalMinutes'] != null && (src['totalMinutes'] as int) > 0)) as bool,
    );
  }
}

/// ===== Repository =====
///
/// Cập nhật để đồng bộ với Backend API đã thiết kế:
/// - POST /api/user-activity -> recordActivity (cộng dồn)
/// - GET /api/user-activity/streak/{userId} -> getStreakData
/// - GET /api/user-activity/{userId}/check-studied/{date} -> getTodayStatus
/// - GET /api/user-activity/{userId}/total-minutes/{date} -> getTodayTotalMinutes
///
class StreakRepository {
  static String get _base => ProgressRepository.streakBase;

  /// Lấy toàn bộ dữ liệu streak & calendar
  static Future<StreakData> getStreakData(int userId, {int months = 3}) async {
    final token = await ProgressRepository.getToken();
    final res = await http.get(
      Uri.parse('$_base/streak/$userId?months=$months'),
      headers: ProgressRepository.authHeaders(token),
    );

    if (res.statusCode == 200) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return StreakData.fromJson(j);
    }

    if (res.statusCode == 404) {
      return StreakData(
        currentStreak: 0,
        bestStreak: 0,
        totalDays: 0,
        todayMinutes: 0,
        todayStudied: false,
        calendarDays: [],
      );
    }

    throw Exception('getStreakData failed ${res.statusCode}: ${res.body}');
  }

  /// Ghi nhận thời gian học (CỘNG DỒN theo backend mới)
  static Future<RecordActivityResult> recordActivity({
    required int userId,
    required int additionalMinutes,
  }) async {
    final token = await ProgressRepository.getToken();
    final today = DateTime.now().toIso8601String().split('T').first;

    final res = await http.post(
      Uri.parse('$_base'),
      headers: {
        ...ProgressRepository.authHeaders(token),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'activityDate': today,
        'additionalMinutes': additionalMinutes,
      }),
    );

    if (res.statusCode == 200) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return RecordActivityResult.fromJson(j);
    }

    throw Exception('recordActivity failed ${res.statusCode}: ${res.body}');
  }

  /// Trạng thái học hôm nay - dùng endpoint check-studied
  static Future<TodayStatus> getTodayStatus(int userId) async {
    final token = await ProgressRepository.getToken();
    final today = DateTime.now().toIso8601String().split('T').first;

    final res = await http.get(
      Uri.parse('$_base/$userId/check-studied/$today'),
      headers: ProgressRepository.authHeaders(token),
    );

    if (res.statusCode == 200) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return TodayStatus.fromJson(j);
    }

    return TodayStatus(totalMinutes: 0, isStudiedDay: false, hasActivity: false);
  }

  /// Tổng số phút hôm nay - dùng endpoint total-minutes
  static Future<int> getTodayTotalMinutes(int userId) async {
    final token = await ProgressRepository.getToken();
    final today = DateTime.now().toIso8601String().split('T').first;

    final res = await http.get(
      Uri.parse('$_base/$userId/total-minutes/$today'),
      headers: ProgressRepository.authHeaders(token),
    );

    if (res.statusCode == 200) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (j['success'] == true) {
        return (j['totalMinutes'] ?? 0) as int;
      }
      // Fallback: try to read from data field
      final data = j['data'];
      if (data is Map<String, dynamic>) {
        return (data['totalMinutes'] ?? 0) as int;
      }
      return (j['totalMinutes'] ?? 0) as int;
    }

    return 0;
  }

  /// Lấy thống kê theo tháng
  static Future<Map<String, dynamic>> getMonthlyStats({
    required int userId,
    required int year,
    required int month,
  }) async {
    final token = await ProgressRepository.getToken();

    final res = await http.get(
      Uri.parse('$_base/$userId/monthly-stats?year=$year&month=$month'),
      headers: ProgressRepository.authHeaders(token),
    );

    if (res.statusCode == 200) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return j['data'] ?? {};
    }

    throw Exception('getMonthlyStats failed ${res.statusCode}: ${res.body}');
  }

  /// Lấy activities trong khoảng thời gian
  static Future<List<Map<String, dynamic>>> getActivitiesInPeriod({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final token = await ProgressRepository.getToken();
    final startStr = startDate.toIso8601String().split('T').first;
    final endStr = endDate.toIso8601String().split('T').first;

    final res = await http.get(
      Uri.parse('$_base/$userId/period?startDate=$startStr&endDate=$endStr'),
      headers: ProgressRepository.authHeaders(token),
    );

    if (res.statusCode == 200) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (j['success'] == true) {
        final data = j['data'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
    }

    return [];
  }

  /// Touch/Check-in nhanh - ghi nhận 1 phút học
  static Future<RecordActivityResult> checkInToday(int userId) async {
    return await recordActivity(
      userId: userId,
      additionalMinutes: 1,
    );
  }

  /// Touch - alias cho checkInToday
  static Future<RecordActivityResult> touch(int userId) async {
    return await checkInToday(userId);
  }
}