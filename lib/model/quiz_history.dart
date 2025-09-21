// quiz_history_model.dart
class QuizHistory {
  final int id;
  final int quizId;
  final int attemptNo;
  final double score;
  final int correctAnswers;
  final int totalQuestions;
  final int durationSeconds;
  final DateTime completedAt;

  QuizHistory({
    required this.id,
    required this.quizId,
    required this.attemptNo,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.durationSeconds,
    required this.completedAt,
  });

  factory QuizHistory.fromJson(Map<String, dynamic> json) {
    return QuizHistory(
      id: json['id'],
      quizId: json['quiz_id'],
      attemptNo: json['attempt_no'],
      score: json['score'].toDouble(),
      correctAnswers: json['correct_answers'],
      totalQuestions: json['total_questions'],
      durationSeconds: json['duration_seconds'],
      completedAt: DateTime.parse(json['completed_at']),
    );
  }
}