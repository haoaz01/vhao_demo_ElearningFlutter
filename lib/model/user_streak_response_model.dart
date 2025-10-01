import 'calendar_day_model.dart';

class UserStreakResponse {
  final int userId;
  final int currentStreak;
  final DateTime? streakStartDate;
  final DateTime? streakEndDate;
  final List<DateTime> streakDays;
  final List<CalendarDayDTO> calendarDays;

  UserStreakResponse({
    required this.userId,
    required this.currentStreak,
    this.streakStartDate,
    this.streakEndDate,
    required this.streakDays,
    required this.calendarDays,
  });

  factory UserStreakResponse.fromJson(Map<String, dynamic> json) {
    // Xử lý streakDays - backend trả về List<LocalDate> (chỉ date, không có time)
    final streakDays = (json['streakDays'] as List<dynamic>?)
        ?.map((e) {
      if (e is String) {
        return DateTime.parse(e);
      }
      return DateTime.now();
    })
        .toList() ?? [];

    // Xử lý calendarDays
    final calendarDays = (json['calendarDays'] as List<dynamic>?)
        ?.map((e) => CalendarDayDTO.fromJson(e))
        .toList() ?? [];

    // Xử lý streakStartDate và streakEndDate
    DateTime? parseNullableDate(dynamic date) {
      if (date == null) return null;
      try {
        return DateTime.parse(date.toString());
      } catch (e) {
        return null;
      }
    }

    return UserStreakResponse(
      userId: json['userId'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      streakStartDate: parseNullableDate(json['streakStartDate']),
      streakEndDate: parseNullableDate(json['streakEndDate']),
      streakDays: streakDays,
      calendarDays: calendarDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'streakStartDate': streakStartDate?.toIso8601String().split('T')[0],
      'streakEndDate': streakEndDate?.toIso8601String().split('T')[0],
      'streakDays': streakDays.map((e) => e.toIso8601String().split('T')[0]).toList(),
      'calendarDays': calendarDays.map((e) => e.toJson()).toList(),
    };
  }
}