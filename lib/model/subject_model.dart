import 'chapter_model.dart';

class Subject {
  final int id;
  final String code;
  final String name;
  final int grade;
  final List<Chapter> chapters;

  Subject({
    required this.id,
    required this.code,
    required this.name,
    required this.grade,
    required this.chapters,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    final chaptersJson = json['chapters'] as List<dynamic>? ?? [];
    return Subject(
      id: json['id'] ?? 0,
      code: json['code'] ?? "",
      name: json['name'] ?? "",
      grade: json['grade'] ?? 0,
      chapters: chaptersJson.map((e) => Chapter.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'grade': grade,
      'chapters': chapters.map((e) => e.toJson()).toList(),
    };
  }
}
