class LessonCompletion {
  final int id;
  final int userId;
  final int lessonId;
  final DateTime completedAt;

  LessonCompletion({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.completedAt,
  });

  factory LessonCompletion.fromJson(Map<String, dynamic> json) {
    return LessonCompletion(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      lessonId: json['lessonId'] ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'lessonId': lessonId,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}