class QuizDailyStat {
  final DateTime day;
  final int totalSum;
  final int correctSum;
  final double percentAccuracy;

  QuizDailyStat({
    required this.day,
    required this.totalSum,
    required this.correctSum,
    required this.percentAccuracy,
  });

  factory QuizDailyStat.fromJson(Map<String, dynamic> j) {
    // back-end có thể trả "percentAccuracy" hoặc "dailyPercentage"
    final num? pct =
        (j['percentAccuracy'] as num?) ?? (j['dailyPercentage'] as num?);

    // back-end có thể không có totalSum/correctSum ở endpoint /range
    final int total = (j['totalSum'] as num?)?.toInt() ?? 0;
    final int correct = (j['correctSum'] as num?)?.toInt() ?? 0;

    // day là String "YYYY-MM-DD"
    final String dayStr = j['day']?.toString() ?? '';
    final DateTime d = DateTime.tryParse(dayStr) ??
        // fallback nếu trả ISO date-time
        DateTime.tryParse(dayStr.split('T').first) ??
        DateTime.now();

    return QuizDailyStat(
      day: d,
      totalSum: total,
      correctSum: correct,
      percentAccuracy: (pct ?? 0).toDouble(),
    );
  }
}
