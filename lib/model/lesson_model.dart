
import 'content_item_model.dart';
import 'exercise_model.dart';

class Lesson {
  final int id;
  final String title;
  final String videoUrl;
  List<ContentItem> contents;
  final List<Exercise> exercises;

  Lesson({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.contents = const [],
    this.exercises = const [],
  });

  Lesson copyWith({
    int? id,
    String? title,
    String? videoUrl,
    List<ContentItem>? contents,
    List<Exercise>? exercises,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      contents: contents ?? this.contents,
      exercises: exercises ?? this.exercises,
    );
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final contentsData = json['contents'] as List<dynamic>? ?? [];
    List<ContentItem> contents = contentsData.map((c) => ContentItem.fromJson(c)).toList();

    final exercisesData = json['exercises'] as List<dynamic>? ?? [];
    List<Exercise> exercises = exercisesData.map((e) => Exercise.fromJson(e)).toList();

    return Lesson(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      videoUrl: json['video_url'] ?? '',
      contents: contents,
      exercises: exercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'video_url': videoUrl,
      'contents': contents.map((c) => c.toJson()).toList(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}
