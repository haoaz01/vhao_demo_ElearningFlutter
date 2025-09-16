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
      id: json['id'] ?? 0, // Provide default if null
      fileName: json['file_name'] ?? '', // Handle null and key mismatch
      description: json['description'] ?? '',
      subject: json['subject'] ?? '',
      grade: json['grade'] ?? '',
      examType: json['exam_type'] ?? '', // Handle key mismatch
      uploadDate: DateTime.parse(json['upload_date'] ?? DateTime.now().toString()), // Handle key mismatch and null
    );
  }
}