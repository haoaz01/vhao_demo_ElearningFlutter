import 'package:flutter_elearning_application/model/question_content_model.dart';
import 'choice_model.dart';

class Question {
  final int id;
  final List<QuestionContent> contents;
  final String explanation;
  final List<Choice> choices;

  Question({
    required this.id,
    required this.contents,
    required this.explanation,
    this.choices = const [],
  });

  // Getter để tương thích với code cũ
  String get content {
    if (contents.isNotEmpty) {
      return contents.first.contentValue;
    }
    return "";
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    var contentsList = (json['contents'] as List?) ?? [];
    var choicesList = (json['choices'] as List?) ?? [];

    return Question(
      id: json['id'] ?? 0,
      contents: contentsList.map((c) => QuestionContent.fromJson(c)).toList(),
      explanation: json['explanation'] ?? "",
      choices: choicesList.map((c) => Choice.fromJson(c)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contents': contents.map((c) => c.toJson()).toList(),
      'explanation': explanation,
      'choices': choices.map((c) => c.toJson()).toList(),
    };
  }
}