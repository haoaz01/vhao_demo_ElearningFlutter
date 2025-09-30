import 'package:intl/intl.dart';

class QuizDailyStat {
  final DateTime day;
  final double percentAccuracy;
  final int correctSum;
  final int totalSum;

  QuizDailyStat({
    required this.day,
    required this.percentAccuracy,
    required this.correctSum,
    required this.totalSum,
  });

  // Backend có 2 kiểu field %: percentAccuracy | dailyPercentage
  factory QuizDailyStat.fromJson(Map<String, dynamic> json) {
    final pct = (json['percentAccuracy'] ?? json['dailyPercentage'] ?? 0) as num;
    // day có thể là "2025-09-29" hoặc ISO string
    final dayStr = json['day']?.toString();
    final day = dayStr == null ? DateTime.now() : DateTime.parse(dayStr);
    return QuizDailyStat(
      day: day,
      percentAccuracy: pct.toDouble(),
      correctSum: (json['correctSum'] ?? 0 as num).toInt(),
      totalSum: (json['totalSum'] ?? 0 as num).toInt(),
    );
  }

  /// Dùng để map theo ngày (yyyy-MM-dd)
  String get dayKey => DateFormat('yyyy-MM-dd').format(day);
}
