// lib/models/streak_response.dart
import '../repositories/streak_repository.dart';
import '../model/calendar_day.dart';
class StreakResponse {
  final int userId;
  final int currentStreak;
  final DateTime? streakStartDate;
  final DateTime? streakEndDate;
  final List<DateTime> streakDays;
  final List<CalendarDay> calendarDays;

  StreakResponse({
    required this.userId,
    required this.currentStreak,
    this.streakStartDate,
    this.streakEndDate,
    required this.streakDays,
    required this.calendarDays,
  });

  factory StreakResponse.fromJson(Map<String, dynamic> json) {
    return StreakResponse(
      userId: json['userId'],
      currentStreak: json['currentStreak'],
      streakStartDate: json['streakStartDate'] != null
          ? DateTime.parse(json['streakStartDate'])
          : null,
      streakEndDate: json['streakEndDate'] != null
          ? DateTime.parse(json['streakEndDate'])
          : null,
      streakDays: (json['streakDays'] as List<dynamic>)
          .map((date) => DateTime.parse(date))
          .toList(),
      calendarDays: (json['calendarDays'] as List<dynamic>)
          .map((day) => CalendarDay.fromJson(day))
          .toList(),
    );
  }
}