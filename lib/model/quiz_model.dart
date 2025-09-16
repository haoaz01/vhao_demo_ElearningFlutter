import 'question_model.dart';
import 'chapter_model.dart';

class Quiz {
  final int id;
  final String code;
  final int gradeId;
  final int subjectId;
  final int chapterId;
  final String? chapterTitle;
  final int quizTypeId;
  final DateTime? createdAt;
  final List<Question> questions;
  final Chapter? chapter;

  Quiz({
    required this.id,
    required this.code,
    required this.gradeId,
    required this.subjectId,
    required this.chapterId,
    this.chapterTitle,
    required this.quizTypeId,
    this.createdAt,
    this.questions = const [],
    this.chapter,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    var questionList = (json['questions'] as List?) ?? [];

    return Quiz(
      id: json['id'] ?? 0,
      code: json['code'] ?? "",
      // Use underscore field names from JSON
      gradeId: json['grade_id'] ?? 0,       // Changed from gradeId to grade_id
      subjectId: json['subject_id'] ?? 0,   // Changed from subjectId to subject_id
      chapterId: json['chapter_id'] ?? 0,   // Changed from chapterId to chapter_id
      chapterTitle: json['chapter_title'] as String?, // Changed from chapterTitle to chapter_title
      quizTypeId: json['quiz_type_id'] ?? 0, // Changed from quizTypeId to quiz_type_id
      createdAt: (json['created_at'] != null && json['created_at'].toString().isNotEmpty)
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      questions: questionList.map((q) => Question.fromJson(q)).toList(),
      chapter: json['chapter'] != null
          ? Chapter.fromJson(json['chapter'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'grade_id': gradeId,          // Use underscore for consistency
      'subject_id': subjectId,      // Use underscore for consistency
      'chapter_id': chapterId,      // Use underscore for consistency
      'chapter_title': chapterTitle, // Use underscore for consistency
      'quiz_type_id': quizTypeId,    // Use underscore for consistency
      'created_at': createdAt?.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'chapter': chapter?.toJson(),
    };
  }
}