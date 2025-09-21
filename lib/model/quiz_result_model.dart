class QuizResult {
  final int id;
  final int quizId;
  final int userId;
  final double score;
  final int correctAnswers;
  final int totalQuestions;
  final int attemptNo;
  final int durationSeconds;
  final String status;
  final DateTime completedAt;
  final DateTime createdAt;

  QuizResult({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.attemptNo,
    required this.durationSeconds,
    required this.status,
    required this.completedAt,
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
      attemptNo: json['attemptNo'] ?? 1,
      durationSeconds: json['durationSeconds'] ?? 0,
      status: json['status'] ?? 'INCOMPLETE',
      completedAt: DateTime.tryParse(json['completedAt'] ?? "") ?? DateTime.now(),
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
      'attemptNo': attemptNo,
      'durationSeconds': durationSeconds,
      'status': status,
      'completedAt': completedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}