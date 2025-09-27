class Progress {
  final int id;
  final int userId;
  final int subjectId;
  final String subjectName;
  final String subjectCode;
  final int grade;
  final int completedLessons;
  final int totalLessons;
  final double progressPercent;
  final DateTime updatedAt;

  Progress({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.grade,
    required this.completedLessons,
    required this.totalLessons,
    required this.progressPercent,
    required this.updatedAt,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      subjectId: json['subjectId'] ?? 0,
      subjectName: json['subjectName'] ?? '',
      subjectCode: json['subjectCode'] ?? '',
      grade: json['grade'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
      totalLessons: json['totalLessons'] ?? 0,
      progressPercent: (json['progressPercent'] ?? 0.0).toDouble(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'grade': grade,
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
      'progressPercent': progressPercent,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}