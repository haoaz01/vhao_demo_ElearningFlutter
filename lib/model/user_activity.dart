// lib/models/user_activity.dart
class UserActivity {
  final int id;
  final int userId;
  final DateTime activityDate;
  final int minutesUsed;

  UserActivity({
    required this.id,
    required this.userId,
    required this.activityDate,
    required this.minutesUsed,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'],
      userId: json['userId'],
      activityDate: DateTime.parse(json['activityDate']),
      minutesUsed: json['minutesUsed'],
    );
  }
}