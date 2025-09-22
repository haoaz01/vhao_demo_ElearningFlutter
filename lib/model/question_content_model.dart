class QuestionContent {
  final String contentType; // "TEXT" hoặc "IMAGE"
  final String contentValue;

  QuestionContent({
    required this.contentType,
    required this.contentValue,
  });

  factory QuestionContent.fromJson(Map<String, dynamic> json) {
    return QuestionContent(
      contentType: json['content_type'] ?? "",
      contentValue: json['content_value'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content_type': contentType,
      'content_value': contentValue,
    };
  }
}