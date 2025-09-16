import 'choice_model.dart';

class Question {
  final int id;
  final String content;
  final String explanation;
  final List<Choice> choices;

  Question({
    required this.id,
    required this.content,
    required this.explanation,
    this.choices = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    var choicesList = (json['choices'] as List?) ?? [];
    return Question(
      id: json['id'] ?? 0,
      content: json['content'] ?? "",
      explanation: json['explanation'] ?? "",
      choices: choicesList.map((c) => Choice.fromJson(c)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'explanation': explanation,
      'choices': choices.map((c) => c.toJson()).toList(),
    };
  }
}
