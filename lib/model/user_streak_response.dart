import 'calendar_day.dart';

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
    return UserStreakResponse(
      userId: json['userId'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      streakStartDate: json['streakStartDate'] != null
          ? DateTime.tryParse(json['streakStartDate'])
          : null,
      streakEndDate: json['streakEndDate'] != null
          ? DateTime.tryParse(json['streakEndDate'])
          : null,
      streakDays: (json['streakDays'] as List<dynamic>?)
          ?.map((e) => DateTime.tryParse(e.toString())!)
          .whereType<DateTime>()
          .toList() ??
          [],
      calendarDays: (json['calendarDays'] as List<dynamic>?)
          ?.map((e) => CalendarDayDTO.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'streakStartDate': streakStartDate?.toIso8601String(),
      'streakEndDate': streakEndDate?.toIso8601String(),
      'streakDays': streakDays.map((e) => e.toIso8601String()).toList(),
      'calendarDays': calendarDays.map((e) => e.toJson()).toList(),
    };
  }
}
