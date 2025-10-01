class TodayInfoResponse {
  final bool success;
  final DateTime date;
  final int totalMinutes;
  final bool isStudiedDay;
  final int minStudyMinutes;
  final int remainingMinutes;

  TodayInfoResponse({
    required this.success,
    required this.date,
    required this.totalMinutes,
    required this.isStudiedDay,
    required this.minStudyMinutes,
    required this.remainingMinutes,
  });

  factory TodayInfoResponse.fromJson(Map<String, dynamic> json) {
    return TodayInfoResponse(
      success: json['success'] ?? false,
      date: DateTime.parse(json['date'].toString()),
      totalMinutes: json['totalMinutes'] ?? 0,
      isStudiedDay: json['isStudiedDay'] ?? false,
      minStudyMinutes: json['minStudyMinutes'] ?? 15,
      remainingMinutes: json['remainingMinutes'] ?? 0,
    );
  }
}