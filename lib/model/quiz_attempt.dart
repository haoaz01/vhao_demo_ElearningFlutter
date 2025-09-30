class QuizAttempt {
  final int attemptNo;
  final double score10;       // thang 10
  final int totalQuestions;
  final int correctAnswers;
  final int durationSeconds;
  final DateTime completedAt;

  QuizAttempt({
    required this.attemptNo,
    required this.score10,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.durationSeconds,
    required this.completedAt,
  });

  // Ánh xạ từ /best-score (backend log cho thấy: bestCorrectAnswers, totalQuestions, durationSeconds, completedAt)
  factory QuizAttempt.fromBestScoreJson(Map<String, dynamic> j) {
    final tq = (j['totalQuestions'] ?? 0) as int;
    final ca = (j['bestCorrectAnswers'] ?? j['correctAnswers'] ?? 0) as int;
    final score10 = tq > 0 ? (ca / tq) * 10.0 : 0.0;
    return QuizAttempt(
      attemptNo: 1,
      score10: score10,
      totalQuestions: tq,
      correctAnswers: ca,
      durationSeconds: (j['durationSeconds'] ?? 0) as int,
      completedAt: DateTime.tryParse(j['completedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
