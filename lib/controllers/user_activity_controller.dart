// import 'dart:async';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:get/get.dart';
import '../model/calendar_day.dart';
import '../model/user_activity_dto.dart';
import '../model/user_streak_response.dart';
import '../repositories/user_activity_repository.dart';

class UserActivityController extends GetxController {
  final UserActivityRepository repository;

  UserActivityController({required this.repository});

  UserStreakResponse? _streakData;
  UserStreakResponse? get streakData => _streakData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  String? _error;
  String? get error => _error;

  int _currentSessionMinutes = 0;
  int get currentSessionMinutes => _currentSessionMinutes;

  DateTime? _sessionStartTime;
  bool get isSessionActive => _sessionStartTime != null;

  Timer? _sessionTimer;

  Future<void> refreshData(int userId) async {
    await fetchUserStreakAndCalendar(userId);
  }

  Future<void> forceRefresh(int userId) async {
    _streakData = null;
    _error = null;
    await fetchUserStreakAndCalendar(userId);
  }

  Future<void> fetchUserStreakAndCalendar(int userId, {int months = 3}) async {
    _isLoading = true;
    _error = null;
    update();

    try {
      final connectionTest = await repository.testConnectionDetailed();
      if (!connectionTest['connected']) {
        _error = 'Không thể kết nối: ${connectionTest['error'] ?? connectionTest['message']}';
        _streakData = null;
        return;
      }

      _streakData = await repository.getUserStreakAndCalendar(userId, months: months);

      if (_streakData == null) {
        _error = 'Dữ liệu rỗng từ server';
      }
    } catch (e, st) {
      print('❌ fetchUserStreakAndCalendar error: $e');
      print(st);
      _error = 'Lỗi: ${e.toString()}';
      _streakData = null;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> recordActivity(int userId, DateTime date, int minutes) async {
    try {
      await repository.recordActivity(userId, date, minutes);
      await fetchUserStreakAndCalendar(userId);
    } catch (e) {
      print('❌ Error recording activity: $e');
      _error = 'Lỗi ghi nhận hoạt động';
      update();
    }
  }

  void startStudySession() {
    _sessionStartTime = DateTime.now();
    _currentSessionMinutes = 0;
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_sessionStartTime != null) {
        _currentSessionMinutes = DateTime.now().difference(_sessionStartTime!).inMinutes;
        update();
      }
    });
    update();
  }

  void endStudySession(int userId) async {
    _sessionTimer?.cancel();
    _sessionTimer = null;

    if (_sessionStartTime != null && _currentSessionMinutes > 0) {
      await recordActivity(userId, DateTime.now(), _currentSessionMinutes);
    }

    _sessionStartTime = null;
    _currentSessionMinutes = 0;
    update();
  }

  void clearError() {
    _error = null;
    update();
  }

  @override
  void onClose() {
    _sessionTimer?.cancel();
    super.onClose();
  }
}
