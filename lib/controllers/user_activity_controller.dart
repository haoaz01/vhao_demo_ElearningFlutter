import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../model/calendar_day_model.dart';
import '../model/user_activity_dto_model.dart';
import '../model/user_streak_response_model.dart';
import '../model/streak_info_model.dart';
import '../model/accumulate_session_response_model.dart';
import '../model/today_info_response_model.dart';
import '../repositories/user_activity_repository.dart';

class UserActivityController extends GetxController {
  final UserActivityRepository repository;

  UserActivityController({required this.repository});

  // Dữ liệu streak cơ bản (cho dashboard)
  StreakInfo? _streakInfo;
  StreakInfo? get streakInfo => _streakInfo;

  // Dữ liệu streak + calendar (cho màn hình lịch)
  UserStreakResponse? _streakCalendar;
  UserStreakResponse? get streakCalendar => _streakCalendar;

  // Thông tin hôm nay
  TodayInfoResponse? _todayInfo;
  TodayInfoResponse? get todayInfo => _todayInfo;

  // Trạng thái loading
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingCalendar = false;
  bool get isLoadingCalendar => _isLoadingCalendar;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  String? _error;
  String? get error => _error;

  // Session tracking
  int _currentSessionMinutes = 0;
  int get currentSessionMinutes => _currentSessionMinutes;

  DateTime? _sessionStartTime;
  bool get isSessionActive => _sessionStartTime != null;

  Timer? _sessionTimer;

  // ========== CÁC PHƯƠNG THỨC CHÍNH ==========

  // Refresh toàn bộ dữ liệu
  Future<void> refreshData(int userId) async {
    await Future.wait([
      fetchStreakInfo(userId),
      fetchTodayInfo(userId),
    ]);
  }

  // Force refresh (clear cache)
  Future<void> forceRefresh(int userId) async {
    _streakInfo = null;
    _streakCalendar = null;
    _todayInfo = null;
    _error = null;
    await refreshData(userId);
  }

  // ========== API CALLS ==========

  // Lấy thông tin streak cơ bản (nhanh, cho dashboard)
  Future<void> fetchStreakInfo(int userId) async {
    _isLoading = true;
    _error = null;
    update();

    try {
      final connectionTest = await repository.testConnectionDetailed();
      if (!connectionTest['connected']) {
        _error = 'Không thể kết nối: ${connectionTest['error'] ?? connectionTest['message']}';
        _streakInfo = null;
        return;
      }

      _streakInfo = await repository.getStreakInfo(userId);

      if (_streakInfo == null) {
        _error = 'Dữ liệu streak rỗng từ server';
      }
    } catch (e, st) {
      print('❌ fetchStreakInfo error: $e');
      print(st);
      _error = 'Lỗi khi lấy thông tin streak: ${e.toString()}';
      _streakInfo = null;
    } finally {
      _isLoading = false;
      update();
    }
  }

  // Lấy thông tin streak + calendar (đầy đủ, cho màn hình lịch)
  Future<void> fetchStreakCalendar(int userId, {int months = 3}) async {
    _isLoadingCalendar = true;
    _error = null;
    update();

    try {
      final connectionTest = await repository.testConnectionDetailed();
      if (!connectionTest['connected']) {
        _error = 'Không thể kết nối: ${connectionTest['error'] ?? connectionTest['message']}';
        _streakCalendar = null;
        return;
      }

      _streakCalendar = await repository.getUserStreakAndCalendar(userId, months: months);

      if (_streakCalendar == null) {
        _error = 'Dữ liệu calendar rỗng từ server';
      }
    } catch (e, st) {
      print('❌ fetchStreakCalendar error: $e');
      print(st);
      _error = 'Lỗi khi lấy dữ liệu lịch: ${e.toString()}';
      _streakCalendar = null;
    } finally {
      _isLoadingCalendar = false;
      update();
    }
  }

  // Lấy thông tin hôm nay
  Future<void> fetchTodayInfo(int userId) async {
    try {
      _todayInfo = await repository.getTodayInfo(userId);
      update();
    } catch (e) {
      print('❌ fetchTodayInfo error: $e');
      // Không set error vì đây không phải operation chính
    }
  }

  // ========== SESSION MANAGEMENT ==========

  // Cộng dồn session time (PHƯƠNG THỨC CHÍNH THAY THẾ recordActivity)
  Future<AccumulateSessionResponse?> accumulateSessionTime({
    required int userId,
    required int sessionMinutes,
  }) async {
    try {
      final response = await repository.accumulateSessionTime(
        userId: userId,
        activityDate: DateTime.now(),
        sessionMinutes: sessionMinutes,
      );

      if (response.success) {
        // Cập nhật dữ liệu local ngay lập tức
        if (_todayInfo != null) {
          _todayInfo = TodayInfoResponse(
            success: true,
            date: _todayInfo!.date,
            totalMinutes: response.newTotalMinutes,
            isStudiedDay: response.isStudiedDay,
            minStudyMinutes: _todayInfo!.minStudyMinutes,
            remainingMinutes: response.remainingMinutes,
          );
        }

        if (_streakInfo != null) {
          _streakInfo = StreakInfo(
            success: true,
            currentStreak: response.isStudiedDay && response.statusChanged
                ? _streakInfo!.currentStreak + 1
                : _streakInfo!.currentStreak,
            todayMinutes: response.newTotalMinutes,
            minStudyMinutes: _streakInfo!.minStudyMinutes,
            remainingMinutes: response.remainingMinutes,
          );
        }

        // Thông báo nếu vừa đạt mục tiêu
        if (response.statusChanged && response.isStudiedDay) {
          _showAchievementNotification();
        }

        update();

        //check
        return null; // ĐÃ SỬA: Trả về response thay vì AccumulateSessionResponse


      } else {
        _error = 'Lỗi từ server: ${response.message}';
        update();
        return null;
      }
    } catch (e) {
      print('❌ accumulateSessionTime error: $e');
      _error = 'Lỗi cộng dồn thời gian học: ${e.toString()}';
      update();
      return null;
    }
  }

  // Bắt đầu study session
  void startStudySession() {
    if (_sessionStartTime != null) return; // Đã có session active

    _sessionStartTime = DateTime.now();
    _currentSessionMinutes = 0;

    // Timer cập nhật mỗi phút
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_sessionStartTime != null) {
        _currentSessionMinutes = DateTime.now().difference(_sessionStartTime!).inMinutes;

        // Tự động gửi cập nhật mỗi 5 phút hoặc khi đạt milestones
        if (_currentSessionMinutes % 5 == 0 || _currentSessionMinutes == 15) {
          _autoSendSessionUpdate();
        }

        update();
      }
    });

    update();
  }

  // Kết thúc study session và gửi dữ liệu
  Future<void> endStudySession(int userId) async {
    _sessionTimer?.cancel();
    _sessionTimer = null;

    if (_sessionStartTime != null && _currentSessionMinutes > 0) {
      await accumulateSessionTime(
        userId: userId,
        sessionMinutes: _currentSessionMinutes,
      );
    }

    _sessionStartTime = null;
    _currentSessionMinutes = 0;
    update();
  }

  // Tự động gửi cập nhật session (cho session dài)
  Future<void> _autoSendSessionUpdate() async {
    // Có thể thêm logic gửi cập nhật tự động ở đây
    // để tránh mất dữ liệu nếu app bị đóng đột ngột
    print('🔄 Auto session update: $_currentSessionMinutes phút');
  }

  // ========== HELPER METHODS ==========

  // Kiểm tra xem hôm nay đã đạt mục tiêu chưa
  bool get isTodayTargetAchieved {
    return _todayInfo?.isStudiedDay == true ||
        _streakInfo?.isTargetAchieved == true;
  }

  // Lấy số phút còn lại để đạt mục tiêu
  int get remainingMinutes {
    return _todayInfo?.remainingMinutes ??
        _streakInfo?.remainingMinutes ??
        (15 - (_todayInfo?.totalMinutes ?? 0));
  }

  // Lấy tổng số phút học hôm nay
  int get todayTotalMinutes {
    return _todayInfo?.totalMinutes ??
        _streakInfo?.todayMinutes ??
        0;
  }

  // Lấy current streak
  int get currentStreak {
    return _streakInfo?.currentStreak ??
        _streakCalendar?.currentStreak ??
        0;
  }

  // Thông báo thành tích
  void _showAchievementNotification() {
    // Có thể sử dụng Get.snackbar hoặc custom notification
    Get.snackbar(
      '🎉 Chúc mừng!',
      'Bạn đã hoàn thành mục tiêu 15 phút học tập hôm nay!',
      duration: const Duration(seconds: 5),
      snackPosition: SnackPosition.TOP,
    );

    // Hoặc trigger event cho UI
    update();
  }

  // Xóa lỗi
  void clearError() {
    _error = null;
    update();
  }

  // Kiểm tra kết nối
  Future<void> checkConnection() async {
    try {
      final result = await repository.testConnectionDetailed();
      _isConnected = result['connected'] == true;
      update();
    } catch (e) {
      _isConnected = false;
      update();
    }
  }

  @override
  void onClose() {
    _sessionTimer?.cancel();
    super.onClose();
  }

  // ========== DEBUG METHODS ==========

  void printDebugInfo() {
    print('=== DEBUG CONTROLLER STATE ===');
    print('Streak Info: ${_streakInfo?.currentStreak} ngày');
    print('Today Minutes: ${_todayInfo?.totalMinutes} phút');
    print('Session Active: $isSessionActive ($currentSessionMinutes phút)');
    print('Today Target Achieved: $isTodayTargetAchieved');
    print('=============================');
  }
}