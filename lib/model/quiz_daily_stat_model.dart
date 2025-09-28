class QuizDailyStatModel {
  final DateTime day;
  final int correct;
  final int total;
  final double percent;

  QuizDailyStatModel({
    required this.day,
    required this.correct,
    required this.total,
    required this.percent,
  });

  factory QuizDailyStatModel.fromJson(Map<String, dynamic> json) {
    double p = (json['percent'] is num) ? (json['percent'] as num).toDouble() : 0.0;
    if (p <= 1.0) p *= 100; // đề phòng server trả 0..1
    return QuizDailyStatModel(
      day: DateTime.parse(json['day'] as String),
      correct: (json['correct'] ?? 0) as int,
      total: (json['total'] ?? 0) as int,
      percent: p,
    );
  }
}
