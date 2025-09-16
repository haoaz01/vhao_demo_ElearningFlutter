class ExerciseSolution {
  final String type; // "text" hoặc "image"
  final String value;

  ExerciseSolution({
    required this.type,
    required this.value,
  });

  factory ExerciseSolution.fromJson(Map<String, dynamic> json) {
    return ExerciseSolution(
      type: json['type'] ?? 'text',
      value: json['value'] ?? '',
    );
  }

  ExerciseSolution copyWith({
    String? type,
    String? value,
  }) {
    return ExerciseSolution(
      type: type ?? this.type,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
    };
  }
}

class Exercise {
  final int id;
  final String question;
  final List<ExerciseSolution> solutions;

  Exercise({
    required this.id,
    required this.question,
    this.solutions = const [],
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final solutionsData = json['solutions'] as List<dynamic>? ?? [];
    List<ExerciseSolution> solutions = solutionsData
        .map((s) => ExerciseSolution.fromJson(s))
        .toList();

    return Exercise(
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      solutions: solutions,
    );
  }

  Exercise copyWith({
    int? id,
    String? question,
    List<ExerciseSolution>? solutions,
  }) {
    return Exercise(
      id: id ?? this.id,
      question: question ?? this.question,
      solutions: solutions ?? this.solutions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'solutions': solutions.map((s) => s.toJson()).toList(),
    };
  }
}
