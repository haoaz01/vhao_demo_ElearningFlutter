class CheckStudiedResponse {
  final bool success;
  final DateTime date;
  final bool hasActivity;
  final int minutesUsed;
  final bool isStudiedDay;
  final int minStudyMinutes;

  CheckStudiedResponse({
    required this.success,
    required this.date,
    required this.hasActivity,
    required this.minutesUsed,
    required this.isStudiedDay,
    required this.minStudyMinutes,
  });

  factory CheckStudiedResponse.fromJson(Map<String, dynamic> json) {
    return CheckStudiedResponse(
      success: json['success'] ?? false,
      date: DateTime.parse(json['date'].toString()),
      hasActivity: json['hasActivity'] ?? false,
      minutesUsed: json['minutesUsed'] ?? 0,
      isStudiedDay: json['isStudiedDay'] ?? false,
      minStudyMinutes: json['minStudyMinutes'] ?? 15,
    );
  }
}