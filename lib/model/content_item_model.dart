class ContentItem {
  final int id;
  final String type;
  final String value;
  final int order;

  ContentItem({
    required this.id,
    required this.type,
    required this.value,
    required this.order,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] ?? 0,
      type: json['contentType'] ?? 'text',
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