// lib/models/calendar_day.dart
class CalendarDay {
  final DateTime date;
  final bool studied;
  final int minutesStudied;
  final bool isInCurrentStreak;

  CalendarDay({
    required this.date,
    required this.studied,
    required this.minutesStudied,
    required this.isInCurrentStreak,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date: DateTime.parse(json['date']),
      studied: json['studied'] ?? false,
      minutesStudied: (json['minutesStudied'] ?? json['minutesUsed'] ?? 0) as int,
      isInCurrentStreak: json['isInCurrentStreak'] ?? false,
    );
  }
}