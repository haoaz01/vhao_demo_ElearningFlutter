class UserActivityDTO {
  final int? id;
  final int userId;
  final DateTime activityDate;
  final int minutesUsed;

  UserActivityDTO({
    this.id,
    required this.userId,
    required this.activityDate,
    required this.minutesUsed,
  });

  factory UserActivityDTO.fromJson(Map<String, dynamic> json) {
    return UserActivityDTO(
      id: json['id'],
      userId: json['userId'] ?? 0,
      activityDate: DateTime.parse(json['activityDate'].toString()),
      minutesUsed: json['minutesUsed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityDate': activityDate.toIso8601String().split('T')[0],
      'minutesUsed': minutesUsed,
    };
  }
}