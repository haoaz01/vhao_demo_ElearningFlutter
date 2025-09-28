class QuizProgressModel {
  final int total;
  final int completed;
  final double percent;

  QuizProgressModel({
    required this.total,
    required this.completed,
    required this.percent,
  });

  factory QuizProgressModel.fromJson(Map<String, dynamic> json) {
    return QuizProgressModel(
      total: (json['total'] ?? 0) as int,
      completed: (json['completed'] ?? 0) as int,
      percent: (json['percent'] is num) ? (json['percent'] as num).toDouble() : 0.0,
    );
  }
}
