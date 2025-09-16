class ContentItem {
  final int id;
  final String type; // "text" hoặc "image"
  final String value; // nội dung text hoặc link image
  final int order; // thứ tự hiển thị

  ContentItem({
    required this.id,
    required this.type,
    required this.value,
    required this.order,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] ?? 0,
      type: json['content_type'] ?? 'text',
      value: json['content_value'] ?? '',
      order: json['content_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_type': type,
      'content_value': value,
      'content_order': order,
    };
  }
}
