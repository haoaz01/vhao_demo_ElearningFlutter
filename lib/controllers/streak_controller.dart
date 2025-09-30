// lib/controllers/streak_controller.dart
import 'package:get/get.dart';
import '../repositories/streak_repository.dart';
import 'auth_controller.dart';
import '../model/calendar_day.dart';

class StreakController extends GetxController {
  final streakLoaded = false.obs;

  // Các field UI dùng trong Dashboard/StreakScreen
  final currentStreak = 0.obs;
  final bestStreak = 0.obs;
  final totalDays = 0.obs;
  final lastActive = Rxn<DateTime>();
  final todayMinutes = 0.obs;      // Tổng số phút học hôm nay
  final todayStudied = false.obs;  // Hôm nay đã đạt 15+ phút chưa
  final calendarDays = <CalendarDay>[].obs; // Dữ liệu calendar
  final streakDays = <DateTime>[].obs; // Danh sách ngày trong streak hiện tại

  int get _uid => Get.find<AuthController>().userId.value;

  @override
  void onInit() {
    super.onInit();
    fetchStreak();
  }

  Future<void> fetchStreak() async {
    try {
      streakLoaded.value = false;

      // Sửa: Thay bằng getStreakData (method thực tế trong repository)
      final streakData = await StreakRepository.getStreakData(
        _uid,
        months: 3, // Lấy dữ liệu 3 tháng
      );

      // Cập nhật dữ liệu streak
      currentStreak.value = streakData.currentStreak;
      bestStreak.value = streakData.bestStreak ?? currentStreak.value;
      totalDays.value = streakData.totalDays ?? 0;

      // Cập nhật last active
      if (streakData.streakEndDate != null) {
        lastActive.value = streakData.streakEndDate!;
      }

      // Cập nhật calendar và streak days
      calendarDays.value = streakData.calendarDays;

      // Tạo danh sách streak days từ calendar data
      _updateStreakDays(streakData.calendarDays);

      // Cập nhật thông tin hôm nay
      _updateTodayInfo(streakData.calendarDays);

      streakLoaded.value = true;
    } catch (_) {
      streakLoaded.value = true; // vẫn unlock UI, show 0
      _resetToDefault();
    }
  }

  // Cập nhật danh sách ngày trong streak hiện tại
  void _updateStreakDays(List<CalendarDay> days) {
    streakDays.value = days
        .where((day) => day.isInCurrentStreak)
        .map((day) => day.date)
        .toList();
  }

  // Cập nhật thông tin hôm nay từ calendar data
  void _updateTodayInfo(List<CalendarDay> days) {
    final today = DateTime.now();
    final todayFormatted = DateTime(today.year, today.month, today.day);

    final todayData = days.firstWhere(
          (day) {
        final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
        return dayDate == todayFormatted;
      },
      orElse: () => CalendarDay(
        date: todayFormatted,
        studied: false,
        minutesStudied: 0,
        isInCurrentStreak: false,
      ),
    );

    todayMinutes.value = todayData.minutesStudied;
    todayStudied.value = todayData.studied;
  }

  // Ghi nhận thời gian học - CỘNG DỒN theo API mới
  Future<bool> recordStudyTime(int minutes) async {
    try {
      // Sửa: Bỏ activityDate, repository sẽ tự động dùng ngày hiện tại
      final result = await StreakRepository.recordActivity(
        userId: _uid,
        additionalMinutes: minutes,
      );

      // Sửa: Dùng result.saved thay vì result.success
      if (result.saved) {
        // Cập nhật local state từ response
        todayMinutes.value = result.newTotalMinutes;

        final wasStudiedBefore = todayStudied.value;
        todayStudied.value = result.isStudiedDay;

        // Nếu vừa đạt mục tiêu hoặc streak thay đổi -> reload toàn bộ
        if ((!wasStudiedBefore && result.isStudiedDay) || result.statusChanged) {
          await fetchStreak(); // Reload toàn bộ dữ liệu
        } else {
          // Chỉ cập nhật local state nếu không ảnh hưởng streak
          update();
        }

        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Kiểm tra nhanh trạng thái học hôm nay từ server
  Future<void> checkTodayStatus() async {
    try {
      // Sửa: Chỉ truyền userId, không cần date
      final todayData = await StreakRepository.getTodayStatus(_uid);

      todayMinutes.value = todayData.totalMinutes;
      todayStudied.value = todayData.isStudiedDay;
    } catch (_) {
      // Giữ nguyên giá trị hiện tại nếu lỗi
    }
  }

  // Lấy tổng thời gian học trong ngày từ server
  Future<void> refreshTodayMinutes() async {
    try {
      // Sửa: Dùng getTodayTotalMinutes thay vì getTotalMinutesByDate
      final totalMinutes = await StreakRepository.getTodayTotalMinutes(_uid);
      todayMinutes.value = totalMinutes;
      todayStudied.value = totalMinutes >= 15;
    } catch (_) {
      // Giữ nguyên giá trị hiện tại nếu lỗi
    }
  }

  // Check-in/Touch: cập nhật nhanh và đồng bộ lại streak
  Future<void> touch({int minutes = 1}) async {
    try {
      await recordStudyTime(minutes);
    } catch (_) {
      // ignore
    } finally {
      await checkTodayStatus();
    }
  }

  // Check-in today (alias cho touch với 1 phút)
  Future<void> checkInToday() async {
    await touch(minutes: 1);
  }

  // Lấy thống kê theo tháng
  Future<Map<String, dynamic>?> getMonthlyStats(int year, int month) async {
    try {
      return await StreakRepository.getMonthlyStats(
        userId: _uid,
        year: year,
        month: month,
      );
    } catch (_) {
      return null;
    }
  }

  // Lấy activities trong khoảng thời gian
  Future<List<Map<String, dynamic>>?> getActivitiesInPeriod(
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      return await StreakRepository.getActivitiesInPeriod(
        userId: _uid,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (_) {
      return null;
    }
  }

  // Reset về giá trị mặc định
  void _resetToDefault() {
    currentStreak.value = 0;
    bestStreak.value = 0;
    totalDays.value = 0;
    todayMinutes.value = 0;
    todayStudied.value = false;
    lastActive.value = null;
    calendarDays.clear();
    streakDays.clear();
  }

  // Tính % hoàn thành hôm nay
  double get todayProgress {
    if (todayMinutes.value >= 15) return 100.0;
    return (todayMinutes.value / 15 * 100).clamp(0.0, 100.0);
  }

  // Số phút còn lại để đạt mục tiêu
  int get remainingMinutes => (15 - todayMinutes.value).clamp(0, 15);

  // Hôm nay có hoạt động nào chưa (bất kể số phút)
  bool get hasActivityToday => todayMinutes.value > 0;

  // Lấy dữ liệu calendar cho tháng cụ thể
  List<CalendarDay> getCalendarForMonth(int year, int month) {
    return calendarDays.where((day) {
      return day.date.year == year && day.date.month == month;
    }).toList();
  }

  // Kiểm tra xem một ngày có trong streak hiện tại không
  bool isDateInCurrentStreak(DateTime date) {
    return streakDays.any((streakDay) {
      return streakDay.year == date.year &&
          streakDay.month == date.month &&
          streakDay.day == date.day;
    });
  }
}