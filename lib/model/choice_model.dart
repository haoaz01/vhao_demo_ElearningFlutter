class Choice {
  final int id;
  final String content; // STRING
  final bool isCorrect;

  Choice({
    required this.id,
    required this.content,
    required this.isCorrect,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      id: json['id'] ?? 0,
      content: json['content'] ?? "",
      isCorrect: json['is_correct'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_correct': isCorrect,
    };
  }
}
