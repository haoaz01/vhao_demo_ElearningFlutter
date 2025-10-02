import 'dart:async';
import 'package:get/get.dart';

import '../model/user_streak_response_model.dart';
import '../model/streak_info_model.dart';
import '../model/accumulate_session_response_model.dart';
import '../model/today_info_response_model.dart';
import '../repositories/user_activity_repository.dart';
import 'package:flutter_elearning_application/helpers/study_session_store.dart';

class UserActivityController extends GetxController {
  final UserActivityRepository repository;
  final StudySessionStore _store = StudySessionStore();

  UserActivityController({required this.repository});

  // ======= State chính =======
  StreakInfo? _streakInfo;                  // Cho dashboard
  StreakInfo? get streakInfo => _streakInfo;

  UserStreakResponse? _streakCalendar;      // Cho màn hình lịch
  UserStreakResponse? get streakCalendar => _streakCalendar;

  TodayInfoResponse? _todayInfo;            // Thông tin hôm nay
  TodayInfoResponse? get todayInfo => _todayInfo;

  bool _flushInProgress = false;  // tránh flush chồng lên nhau
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingCalendar = false;
  bool get isLoadingCalendar => _isLoadingCalendar;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  String? _error;
  String? get error => _error;

  // ======= Session tracking =======
  int _sessionAccruedMinutes = 0;                 // phút đã tích trong phiên hiện tại
  int get currentSessionMinutes =>
      _sessionAccruedMinutes + (_bufferedSeconds ~/ 60);

  DateTime? _sessionStartTime;                    // null = không có phiên
  bool get isSessionActive => _sessionStartTime != null;

  Timer? _tickTimer;                              // tick 1s
  Timer? _safetyFlushTimer;                       // flush an toàn mỗi 2 phút
  int _bufferedSeconds = 0;                       // số giây đang đệm (chưa gửi)

  // Progress 0..1 để vẽ progress 15 phút theo giây
  double get todayProgressSeconds {
    final totalSecs = (todayTotalMinutes * 60) + _bufferedSeconds;
    return (totalSecs / (15 * 60)).clamp(0.0, 1.0);
  }

  // ======= Refresh helpers =======
  Future<void> refreshData(int userId) async {
    await Future.wait([
      fetchStreakInfo(userId),
      fetchTodayInfo(userId),
    ]);
  }

  Future<void> forceRefresh(int userId) async {
    _streakInfo = null;
    _streakCalendar = null;
    _todayInfo = null;
    _error = null;
    await refreshData(userId);
  }

  // ======= API calls =======
  Future<void> fetchStreakInfo(int userId) async {
    _isLoading = true;
    _error = null;
    update();

    try {
      final conn = await repository.testConnectionDetailed(userId: userId); // 👈 thêm userId
      if (conn['connected'] != true) {
        _error = 'Không thể kết nối: ${conn['error'] ?? conn['message']}';
        _streakInfo = null;
        return;
      }

      _streakInfo = await repository.getStreakInfo(userId);
      if (_streakInfo == null) {
        _error = 'Dữ liệu streak rỗng từ server';
      }
    } catch (e, st) {
      print('❌ fetchStreakInfo error: $e\n$st');
      _error = 'Lỗi khi lấy thông tin streak: $e';
      _streakInfo = null;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> fetchStreakCalendar(int userId, {int months = 3}) async {
    _isLoadingCalendar = true;
    _error = null;
    update();

    try {
      final conn = await repository.testConnectionDetailed(userId: userId); // 👈 thêm userId
      if (conn['connected'] != true) {
        _error = 'Không thể kết nối: ${conn['error'] ?? conn['message']}';
        _streakCalendar = null;
        return;
      }

      _streakCalendar =
      await repository.getUserStreakAndCalendar(userId, months: months);

      if (_streakCalendar == null) {
        _error = 'Dữ liệu calendar rỗng từ server';
      }
    } catch (e, st) {
      print('❌ fetchStreakCalendar error: $e\n$st');
      _error = 'Lỗi khi lấy dữ liệu lịch: $e';
      _streakCalendar = null;
    } finally {
      _isLoadingCalendar = false;
      update();
    }
  }

  Future<void> fetchTodayInfo(int userId) async {
    try {
      _todayInfo = await repository.getTodayInfo(userId);
      update();
    } catch (e) {
      // ignore: avoid_print
      print('❌ fetchTodayInfo error: $e');
    }
  }
  Future<void> resetSessionForNewUser() async {

    _sessionStartTime = null;
    _sessionAccruedMinutes = 0;
    _bufferedSeconds = 0;
    await _store.clear();
    _todayInfo = null;
    _streakInfo = null;
    _streakCalendar = null;
    update();
  }
  // ======= Session management =======
  /// Cộng dồn thời gian học (thay thế recordActivity)
  Future<AccumulateSessionResponse?> accumulateSessionTime({
    required int userId,
    required int sessionMinutes,
  }) async {
    try {
      // Gửi ngày theo local (date-only) để backend không lệch múi giờ
      final now = DateTime.now();
      final activityDate = DateTime(now.year, now.month, now.day);
      print("➡️ accumulateSessionTime(user=$userId, +$sessionMinutes', date=$activityDate)");
      final response = await repository.accumulateSessionTime(
        userId: userId,
        activityDate: activityDate,
        sessionMinutes: sessionMinutes,
      );
      print("⬅️ server newTotal=${response.newTotalMinutes}, isStudied=${response.isStudiedDay}, statusChanged=${response.statusChanged}");
      if (response.success) {
        // Cập nhật local (TodayInfo)
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

        // Cập nhật local (StreakInfo)
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

        // Nếu vừa đạt mốc, refresh để tô lịch ngay
        if (response.statusChanged && response.isStudiedDay) {
          _showAchievementNotification();
          await Future.wait([
            fetchTodayInfo(userId),
            fetchStreakInfo(userId),
            fetchStreakCalendar(userId),
          ]);
        }

        update();
        return response;
      } else {
        _error = 'Lỗi từ server: ${response.message}';
        update();
        return response;
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ accumulateSessionTime error: $e');
      _error = 'Lỗi cộng dồn thời gian học: $e';
      update();
      return null;
    }
  }

  /// Đảm bảo auto-session bật khi user vào app/màn
  Future<void> ensureAutoSessionStarted(int userId) async {
    final restored = await _store.loadIfSameDay();

    if (_sessionStartTime == null) {
      _sessionStartTime = restored?.sessionStartTime ?? DateTime.now();
      _bufferedSeconds = restored?.bufferedSeconds ?? 0;
      _sessionAccruedMinutes = restored?.sessionAccruedMinutes ?? 0;

      // ✅ Bù thời gian trôi khi app ở background
      final elapsedSinceStart =
          DateTime.now().difference(_sessionStartTime!).inSeconds;
      final alreadyCounted = _sessionAccruedMinutes * 60 + _bufferedSeconds;
      final delta = elapsedSinceStart - alreadyCounted;
      if (delta > 0) {
        _bufferedSeconds += delta;

        // nếu đủ phút, flush ngay
        final m = _bufferedSeconds ~/ 60;
        if (m > 0) {
          _bufferedSeconds = _bufferedSeconds % 60;
          _sessionAccruedMinutes += m;
          await accumulateSessionTime(userId: userId, sessionMinutes: m);
        }

        await _store.save(
          sessionStartTime: _sessionStartTime,
          bufferedSeconds: _bufferedSeconds,
          sessionAccruedMinutes: _sessionAccruedMinutes,
        );
      }
    }

    _startTickTimer(userId);
    update();
  }

  /// Khởi động timers: tick 1s + safety flush 2 phút
  void _startTickTimer(int userId) {
    // Hủy timers cũ trước khi tạo mới
    _tickTimer?.cancel();
    _safetyFlushTimer?.cancel();

    // Tick 1 giây – tăng buffer, đủ 60s thì flush 1 phút
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_sessionStartTime == null) return;

      _bufferedSeconds += 1;

      // Snapshot mỗi 5s
      if (_bufferedSeconds % 5 == 0) {
        await _store.save(
          sessionStartTime: _sessionStartTime,
          bufferedSeconds: _bufferedSeconds,
          sessionAccruedMinutes: _sessionAccruedMinutes,
        );
      }

      // Đủ 60s -> flush
      if (_bufferedSeconds >= 60 && !_flushInProgress) {
        final m = _bufferedSeconds ~/ 60;
        _bufferedSeconds = _bufferedSeconds % 60;
        _sessionAccruedMinutes += m;

        _flushInProgress = true;
        try {
          // ⏱ LOG CHÍNH: xem flush bao nhiêu phút & tổng đã tích
          print("⏱ [tick] Flush $m phút cho user $userId | Accrued=$_sessionAccruedMinutes");
          await accumulateSessionTime(userId: userId, sessionMinutes: m);

          await _store.save(
            sessionStartTime: _sessionStartTime,
            bufferedSeconds: _bufferedSeconds,
            sessionAccruedMinutes: _sessionAccruedMinutes,
          );
        } finally {
          _flushInProgress = false;
        }
      }

      update();
    });

    // Safety flush 2 phút/lần – nếu đã tích >= 60s mà chưa flush thì flush
    _safetyFlushTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      if (_sessionStartTime == null) return;

      final m = _bufferedSeconds ~/ 60;
      if (m > 0 && !_flushInProgress) {
        _bufferedSeconds = _bufferedSeconds % 60;
        _sessionAccruedMinutes += m;

        _flushInProgress = true;
        try {
          // ⏱ LOG CHÍNH: safety flush
          print("⏱ [safety] Flush $m phút cho user $userId | Accrued=$_sessionAccruedMinutes");
          await accumulateSessionTime(userId: userId, sessionMinutes: m);

          await _store.save(
            sessionStartTime: _sessionStartTime,
            bufferedSeconds: _bufferedSeconds,
            sessionAccruedMinutes: _sessionAccruedMinutes,
          );
        } finally {
          _flushInProgress = false;
        }

        update();
      }
    });
  }

  /// Kết thúc phiên (flush phần phút còn lại nếu có)
  Future<void> endStudySession(int userId) async {
    await _store.save(
      sessionStartTime: _sessionStartTime,
      bufferedSeconds: _bufferedSeconds,
      sessionAccruedMinutes: _sessionAccruedMinutes,
    );

    _tickTimer?.cancel();
    _safetyFlushTimer?.cancel();
    _tickTimer = null;
    _safetyFlushTimer = null;

    final m = _bufferedSeconds ~/ 60;
    if (m > 0) {
      _bufferedSeconds = _bufferedSeconds % 60;
      _sessionAccruedMinutes += m;
      await accumulateSessionTime(userId: userId, sessionMinutes: m);
    }

    _sessionStartTime = null;
    _sessionAccruedMinutes = 0;
    _bufferedSeconds = 0;
    await _store.clear();
    update();
  }

  /// Lưu snapshot thủ công (khi app vào background, v.v.)
  Future<void> persistSessionSnapshot() async {
    await _store.save(
      sessionStartTime: _sessionStartTime,
      bufferedSeconds: _bufferedSeconds,
      sessionAccruedMinutes: _sessionAccruedMinutes,
    );
  }

  // ======= Helpers =======
  bool get isTodayTargetAchieved {
    return _todayInfo?.isStudiedDay == true ||
        _streakInfo?.isTargetAchieved == true;
  }

  int get remainingMinutes {
    return _todayInfo?.remainingMinutes ??
        _streakInfo?.remainingMinutes ??
        (15 - (_todayInfo?.totalMinutes ?? 0));
  }

  int get todayTotalMinutes {
    return _todayInfo?.totalMinutes ?? _streakInfo?.todayMinutes ?? 0;
    // (local bufferedSeconds chỉ để hiển thị progress mượt, không cộng vào con số phút này)
  }

  int get currentStreak => _streakInfo?.currentStreak ?? 0;

  void _showAchievementNotification() {
    Get.snackbar(
      '🎉 Chúc mừng!',
      'Bạn đã hoàn thành mục tiêu 15 phút học tập hôm nay!',
      duration: const Duration(seconds: 5),
      snackPosition: SnackPosition.TOP,
    );
    update();
  }

  void clearError() {
    _error = null;
    update();
  }

  Future<void> checkConnection(int userId) async {
    try {
      final result = await repository.testConnectionDetailed(userId: userId); // 👈
      _isConnected = result['connected'] == true;
      update();
    } catch (_) {
      _isConnected = false;
      update();
    }
  }

  @override
  void onClose() {
    _tickTimer?.cancel();
    _safetyFlushTimer?.cancel();
    super.onClose();
  }

  // ======= Debug =======
  void printDebugInfo() {
    // ignore: avoid_print
    print('=== DEBUG CONTROLLER STATE ===');
    // ignore: avoid_print
    print('Streak Info: ${_streakInfo?.currentStreak} ngày');
    // ignore: avoid_print
    print('Today Minutes: ${_todayInfo?.totalMinutes} phút');
    // ignore: avoid_print
    print('Session Active: $isSessionActive ($currentSessionMinutes phút)');
    // ignore: avoid_print
    print('Today Target Achieved: $isTodayTargetAchieved');
    // ignore: avoid_print
    print('=============================');
  }
}
