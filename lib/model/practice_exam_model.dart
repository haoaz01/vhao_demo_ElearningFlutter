class PracticeExam {
  final int id;
  final String fileName;
  final String description;
  final String subject;
  final String grade;       // giữ String
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
      fileName: json['fileName'] ?? '',
      description: json['description'] ?? '',
      subject: json['subject']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',  // ✅ ép sang String
      examType: json['examType']?.toString() ?? '',
      uploadDate: DateTime.tryParse(json['uploadDate']?.toString() ?? '')
          ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'description': description,
      'subject': subject,
      'grade': grade,
      'examType': examType,
      'uploadDate': uploadDate.toIso8601String(),
    };
  }
}
