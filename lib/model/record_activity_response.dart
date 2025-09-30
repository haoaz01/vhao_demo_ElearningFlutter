// lib/models/record_activity_response.dart
import 'package:flutter_elearning_application/model/user_activity.dart';

class RecordActivityResponse {
  final bool success;
  final bool saved;
  final UserActivity? data;
  final int previousTotalMinutes;
  final int additionalMinutes;
  final int newTotalMinutes;
  final bool isStudiedDay;
  final bool wasStudiedBefore;
  final bool statusChanged;
  final String message;

  RecordActivityResponse({
    required this.success,
    required this.saved,
    this.data,
    required this.previousTotalMinutes,
    required this.additionalMinutes,
    required this.newTotalMinutes,
    required this.isStudiedDay,
    required this.wasStudiedBefore,
    required this.statusChanged,
    required this.message,
  });

  factory RecordActivityResponse.fromJson(Map<String, dynamic> json) {
    return RecordActivityResponse(
      success: json['success'],
      saved: json['saved'],
      data: json['data'] != null ? UserActivity.fromJson(json['data']) : null,
      previousTotalMinutes: json['previousTotalMinutes'],
      additionalMinutes: json['additionalMinutes'],
      newTotalMinutes: json['newTotalMinutes'],
      isStudiedDay: json['isStudiedDay'],
      wasStudiedBefore: json['wasStudiedBefore'],
      statusChanged: json['statusChanged'],
      message: json['message'],
    );
  }
}