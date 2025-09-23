import 'exercise_model.dart';
import 'lesson_content_model.dart';

class Lesson {
  final int id;
  final String title;
  final String videoUrl;
  List<LessonContent> contents;
  List<Exercise> exercises;
  final int? subjectId;
  final String? subjectName;
  final String? chapterName;
  final int? grade; // Thêm trường grade

  Lesson({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.contents = const [],
    this.exercises = const [],
    this.subjectId,
    this.subjectName,
    this.chapterName,
    this.grade, // Thêm vào constructor
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final contentsData = json['contents'] as List<dynamic>? ?? [];
    List<LessonContent> contents = contentsData.map((c) => LessonContent.fromJson(c)).toList();

    final exercisesData = json['exercises'] as List<dynamic>? ?? [];
    List<Exercise> exercises = exercisesData.map((e) => Exercise.fromJson(e)).toList();

    return Lesson(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      contents: contents,
      exercises: exercises,
      subjectId: json['subjectId'],
      subjectName: json['subjectName'],
      chapterName: json['chapterName'],
      grade: json['grade'], // Thêm từ JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'videoUrl': videoUrl,
      'contents': contents.map((c) => c.toJson()).toList(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'subjectId': subjectId,
      'subjectName': subjectName,
      'chapterName': chapterName,
      'grade': grade, // Thêm vào JSON
    };
  }

  Lesson copyWith({
    int? id,
    String? title,
    String? videoUrl,
    List<LessonContent>? contents,
    List<Exercise>? exercises,
    int? subjectId,
    String? subjectName,
    String? chapterName,
    int? grade, // Thêm vào copyWith
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      contents: contents ?? this.contents,
      exercises: exercises ?? this.exercises,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      chapterName: chapterName ?? this.chapterName,
      grade: grade ?? this.grade, // Thêm vào copyWith
    );
  }
}