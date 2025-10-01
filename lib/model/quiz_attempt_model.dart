class QuizAttempt {
  final int attemptNo;
  final double score10;
  final DateTime completedAt;
  final int durationSeconds;
  final int correctAnswers;
  final int totalQuestions;

  QuizAttempt({
    required this.attemptNo,
    required this.score10,
    required this.completedAt,
    required this.durationSeconds,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  // Dùng cho danh sách lịch sử attempt
  factory QuizAttempt.fromJson(Map<String, dynamic> j) {
    return QuizAttempt(
      attemptNo: j['attempt_no'] ?? 0,
      score10: (j['score'] as num?)?.toDouble() ?? 0.0,
      completedAt: DateTime.parse(j['completed_at']),
      durationSeconds: j['duration_seconds'] ?? 0,
      correctAnswers: j['correct_answers'] ?? 0,
      totalQuestions: j['total_questions'] ?? 0,
    );
  }

  // Giữ lại nếu bạn đang dùng best-score (1 dòng)
  factory QuizAttempt.fromBestScoreJson(Map<String, dynamic> j) {
    return QuizAttempt(
      attemptNo: 1,
      score10: (j['score10'] as num?)?.toDouble() ?? 0.0,
      completedAt: DateTime.parse(j['completedAt']),
      durationSeconds: j['durationSeconds'] ?? 0,
      correctAnswers: j['correctAnswers'] ?? 0,
      totalQuestions: j['totalQuestions'] ?? 0,
    );
  }
}
