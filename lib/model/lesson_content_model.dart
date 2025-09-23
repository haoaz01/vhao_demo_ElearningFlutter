class LessonContent {
  final int id;
  final String type;
  final String value;
  final int order;

  LessonContent({
    required this.id,
    required this.type,
    required this.value,
    required this.order,
  });

  factory LessonContent.fromJson(Map<String, dynamic> json) {
    return LessonContent(
      id: json['id'] ?? 0,
      type: json['contentType'] ?? 'TEXT',
      value: json['contentValue'] ?? '',
      order: json['contentOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentType': type,
      'contentValue': value,
      'contentOrder': order,
    };
  }
}