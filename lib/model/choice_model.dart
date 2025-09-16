class Choice {
  final int id;
  final String content;
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
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isCorrect': isCorrect,
    };
  }
}
