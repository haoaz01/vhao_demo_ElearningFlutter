class DailyQuizStat {
  final DateTime day;
  final int totalSum;
  final int correctSum;

  DailyQuizStat({required this.day, required this.totalSum, required this.correctSum});

  double get percentAccuracy => totalSum == 0 ? 0.0 : (correctSum * 100.0 / totalSum);

  factory DailyQuizStat.fromJson(Map<String, dynamic> j) => DailyQuizStat(
    day: DateTime.tryParse(j['day'].toString()) ?? DateTime.now(),
    totalSum: (j['total'] ?? j['totalSum'] ?? 0) as int,
    correctSum: (j['correct'] ?? j['correctSum'] ?? 0) as int,
  );
}
