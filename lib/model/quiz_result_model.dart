// quiz_result_model.dart
class QuizResult {
  final int id;
  final int quizId;
  final int userId;
  final double score;
  final int correctAnswers;
  final int totalQuestions;
  final DateTime createdAt;

  QuizResult({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.createdAt,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['id'] ?? 0,
      quizId: json['quizId'] ?? 0,
      userId: json['userId'] ?? 0,
      score: json['score']?.toDouble() ?? 0.0,
      correctAnswers: json['correctAnswers'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? "") ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'userId': userId,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}