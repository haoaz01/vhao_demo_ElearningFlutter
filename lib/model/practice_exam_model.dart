class PracticeExam {
  final int id;
  final String fileName;
  final String description;
  final String subject;
  final String grade;
  final String examType;
  final DateTime uploadDate;

  PracticeExam({
    required this.id,
    required this.fileName,
    required this.description,
    required this.subject,
    required this.grade,
    required this.examType,
    required this.uploadDate,
  });

  factory PracticeExam.fromJson(Map<String, dynamic> json) {
    return PracticeExam(
      id: json['id'] ?? 0,
      fileName: json['fileName'] ?? '', // ✅ đổi sang camelCase
      description: json['description'] ?? '',
      subject: json['subject'] ?? '',
      grade: json['grade'] ?? '',
      examType: json['examType'] ?? '', // ✅ đổi sang camelCase
      uploadDate: DateTime.tryParse(json['uploadDate'] ?? '') ?? DateTime.now(), // ✅ đổi sang camelCase
    );
  }
}
