import 'lesson_model.dart';

class Chapter {
  final int id;
  final String title;
  final int orderNo;
  List<Lesson> lessons; // gán sau khi fetch riêng

  Chapter({
    required this.id,
    required this.title,
    required this.orderNo,
    List<Lesson>? lessons,
  }) : lessons = lessons ?? [];

  factory Chapter.fromJson(Map<String, dynamic> json) {
    var lessonsList = json['lessons'] as List<dynamic>? ?? [];

    return Chapter(
      id: json['id'] ?? 0,
      title: json['title'] ?? "",
      orderNo: json['orderNo'] ?? 1,
      lessons: lessonsList.map((lessonJson) => Lesson.fromJson(lessonJson)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'orderNo': orderNo,
      'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
    };
  }
}