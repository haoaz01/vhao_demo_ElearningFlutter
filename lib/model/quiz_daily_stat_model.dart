class QuizDailyStat {
  final DateTime day;
  final int correctSum;
  final int totalSum;
  final double percentAccuracy;

  QuizDailyStat({
    required this.day,
    required this.correctSum,
    required this.totalSum,
    required this.percentAccuracy,
  });

  factory QuizDailyStat.fromJson(Map<String, dynamic> json) {
    return QuizDailyStat(
      day: DateTime.parse(json['day']),
      correctSum: json['correctSum'] ?? 0,
      totalSum: json['totalSum'] ?? 0,
      percentAccuracy: (json['percentAccuracy'] ?? 0).toDouble(),
    );
  }
}
