class QuizHistory {
  final int attemptNo;
  final double score;
  final int correctAnswers;
  final int totalQuestions;
  final int durationSeconds;
  final DateTime completedAt;
  final String status;

  QuizHistory({
    required this.attemptNo,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.durationSeconds,
    required this.completedAt,
    required this.status,
  });

  factory QuizHistory.fromJson(Map<String, dynamic> json) {
    return QuizHistory(
      attemptNo: json['attemptNo'] ?? 0,
      score: (json['score'] is int)
          ? (json['score'] as int).toDouble()
          : (json['score'] as num).toDouble(),
      correctAnswers: json['correctAnswers'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      durationSeconds: json['durationSeconds'] ?? 0,
      completedAt: DateTime.parse(json['completedAt']),
      status: json['status'] ?? 'UNKNOWN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attemptNo': attemptNo,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'durationSeconds': durationSeconds,
      'completedAt': completedAt.toIso8601String(),
      'status': status,
    };
  }
}