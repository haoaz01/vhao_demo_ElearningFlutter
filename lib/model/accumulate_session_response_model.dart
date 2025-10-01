import '../repositories/user_activity_repository.dart';
class AccumulateSessionResponse {
  final bool success;
  final int previousTotalMinutes;
  final int sessionMinutes;
  final int newTotalMinutes;
  final bool isStudiedDay;
  final bool wasStudiedBefore;
  final bool statusChanged;
  final int remainingMinutes;
  final String message;

  AccumulateSessionResponse({
    required this.success,
    required this.previousTotalMinutes,
    required this.sessionMinutes,
    required this.newTotalMinutes,
    required this.isStudiedDay,
    required this.wasStudiedBefore,
    required this.statusChanged,
    required this.remainingMinutes,
    required this.message,
  });

  factory AccumulateSessionResponse.fromJson(Map<String, dynamic> json) {
    return AccumulateSessionResponse(
      success: json['success'] ?? false,
      previousTotalMinutes: json['previousTotalMinutes'] ?? 0,
      sessionMinutes: json['sessionMinutes'] ?? 0,
      newTotalMinutes: json['newTotalMinutes'] ?? 0,
      isStudiedDay: json['isStudiedDay'] ?? false,
      wasStudiedBefore: json['wasStudiedBefore'] ?? false,
      statusChanged: json['statusChanged'] ?? false,
      remainingMinutes: json['remainingMinutes'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}