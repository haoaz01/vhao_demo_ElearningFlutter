import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../model/calendar_day.dart';
import '../model/user_streak_response.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_activity_controller.dart';
import '../repositories/user_activity_repository.dart';

class StreakScreen extends StatefulWidget {
  final DateTime? overrideNow;
  const StreakScreen({super.key, this.overrideNow});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  late final UserActivityController userActivityController;
  late final AuthController authController;

  late DateTime now;
  late int currentMonth;
  late int currentYear;

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    userActivityController = Get.isRegistered<UserActivityController>()
        ? Get.find<UserActivityController>()
        : Get.put(UserActivityController(
      repository: UserActivityRepository(client: Get.find()),
    ));
    authController = Get.find<AuthController>();

    now = widget.overrideNow ?? DateTime.now();
    currentMonth = now.month;
    currentYear = now.year;

    _init();
  }



  Future<void> _init() async {
    await userActivityController.fetchUserStreakAndCalendar(authController.userId.value);
  }

  void _changeMonth(int offset) {
    setState(() {
      currentMonth += offset;
      if (currentMonth < 1) {
        currentMonth = 12;
        currentYear--;
      } else if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      }
    });
  }

  List<DateTime> _currentChain() {
    return userActivityController.streakData?.streakDays ?? [];
  }

  bool _isInChain(DateTime d, List<DateTime> chain) {
    final key = _dayKey(d);
    return chain.any((c) => _dayKey(c) == key);
  }

  int _getStudiedDaysInMonth() {
    if (userActivityController.streakData == null) return 0;

    final monthDays = userActivityController.streakData!.calendarDays
        .where((day) => day.date.month == currentMonth && day.date.year == currentYear)
        .toList();
    return monthDays.where((day) => day.studied).length;
  }

  int _getStreakDaysInMonth() {
    if (userActivityController.streakData == null) return 0;

    final monthDays = userActivityController.streakData!.calendarDays
        .where((day) => day.date.month == currentMonth && day.date.year == currentYear)
        .toList();
    return monthDays.where((day) => day.isInCurrentStreak).length;
  }

  CalendarDayDTO? get _todayData {
    if (userActivityController.streakData == null) return null;

    final today = DateTime.now();
    try {
      return userActivityController.streakData!.calendarDays.firstWhere(
            (day) => _dayKey(day.date) == _dayKey(today),
      );
    } catch (e) {
      return CalendarDayDTO(
        date: today,
        studied: false,
        minutesStudied: 0,
        isInCurrentStreak: false,
      );
    }
  }

  double get _todayProgress {
    final today = _todayData;
    if (today == null) return 0.0;
    return (today.minutesStudied / 15.0 * 100).clamp(0.0, 100.0);
  }

  int get _remainingMinutes {
    final today = _todayData;
    if (today == null) return 15;
    return (15 - today.minutesStudied).clamp(0, 15);
  }

  // THÊM PHƯƠNG THỨC TÍNH BEST STREAK
  int _calculateBestStreak() {
    final streakData = userActivityController.streakData;
    if (streakData == null) return 0;

    // Nếu có longestStreak từ API thì dùng, không thì dùng currentStreak
    return streakData.currentStreak; // Tạm thời dùng currentStreak
  }

  @override
  Widget build(BuildContext context) {
    const primary = Colors.green;

    final todayKey = _dayKey(now);
    final monday = _dayKey(todayKey.subtract(Duration(days: todayKey.weekday - 1)));
    final weekDays = List<DateTime>.generate(7, (i) => _dayKey(monday.add(Duration(days: i))));
    const labels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];

    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('🔥 Chuỗi Ngày Học', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          GetBuilder<UserActivityController>(
            builder: (controller) {
              final today = _todayData;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${today?.minutesStudied ?? 0}/15p',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // SỬA NÚT REFRESH
                    if (controller.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                        tooltip: 'Làm mới dữ liệu',
                        onPressed: () async {
                          await controller.refreshData(authController.userId.value);
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ],
        ),
      body: GetBuilder<UserActivityController>(
        builder: (controller) {
          if (controller.isLoading && controller.streakData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      controller.isConnected ? Icons.error_outline : Icons.wifi_off,
                      size: 64,
                      color: controller.isConnected ? Colors.orange : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.isConnected ? 'Lỗi tải dữ liệu' : 'Mất kết nối',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        controller.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            controller.fetchUserStreakAndCalendar(authController.userId.value);
                          },
                          child: const Text('Thử lại'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {
                            // Debug info
                            print('=== DEBUG STREAK INFO ===');
                            print('User ID: ${authController.userId.value}');
                            print('Is Connected: ${controller.isConnected}');
                            print('Is Loading: ${controller.isLoading}');
                            print('Error: ${controller.error}');
                            print('Streak Data: ${controller.streakData}');
                          },
                          child: const Text('Debug Info'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          final chain = _currentChain();
          final studiedDaysThisMonth = _getStudiedDaysInMonth();
          final streakDaysThisMonth = _getStreakDaysInMonth();
          final today = _todayData;
          final todayStudied = today?.studied ?? false;
          final todayMinutes = today?.minutesStudied ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // ===== Tiến trình hôm nay =====
                _buildTodayProgressCard(todayStudied, todayMinutes),
                const SizedBox(height: 12),

                // ===== Strip ngang streak =====
                if (chain.isNotEmpty) _buildStreakChainCard(chain, todayKey),

                // ===== Header số liệu =====
                _buildStatsCard(studiedDaysThisMonth),
                const SizedBox(height: 12),

                // ===== Weekly strip =====
                _buildWeeklyStrip(weekDays, labels, chain, todayKey),
                const SizedBox(height: 12),

                // ===== Monthly calendar =====
                _buildMonthlyCalendar(daysInMonth, studiedDaysThisMonth, streakDaysThisMonth, chain, todayKey),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayProgressCard(bool todayStudied, int todayMinutes) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📊 Hôm nay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                Chip(
                  backgroundColor: todayStudied ? Colors.green : Colors.orange,
                  label: Text(
                    todayStudied ? 'Đã hoàn thành' : 'Chưa hoàn thành',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _todayProgress / 100,
              backgroundColor: Colors.grey[300],
              color: todayStudied ? Colors.green : Colors.orange,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$todayMinutes phút',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_remainingMinutes phút còn lại',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStudySessionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudySessionButton() {
    return GetBuilder<UserActivityController>(
      builder: (controller) {
        if (!controller.isSessionActive) {
          return ElevatedButton(
            onPressed: () {
              controller.startStudySession();
              Get.snackbar(
                'Bắt đầu học',
                'Phiên học đã được bắt đầu. Hãy tập trung!',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow),
                SizedBox(width: 8),
                Text('Bắt Đầu Học'),
              ],
            ),
          );
        } else {
          return Column(
            children: [
              Text(
                '⏰ Đang học: ${controller.currentSessionMinutes} phút',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  controller.endStudySession(authController.userId.value);
                  Get.snackbar(
                    'Kết thúc học',
                    'Đã lưu thời gian học tập!',
                    backgroundColor: Colors.blue,
                    colorText: Colors.white,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Kết Thúc Học'),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStreakChainCard(List<DateTime> chain, DateTime todayKey) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔥 Chuỗi hiện tại: ${chain.length} ngày',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: chain.length,
                itemBuilder: (context, index) {
                  final d = chain[index];
                  final isToday = _dayKey(d) == todayKey;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday ? Border.all(color: Colors.green, width: 2) : null,
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Text(
                      DateFormat('dd/MM').format(d),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(int studiedDaysThisMonth) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Thống kê học tập',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('${userActivityController.streakData?.currentStreak ?? 0}', 'Ngày liên tiếp'),
                _stat('$studiedDaysThisMonth', 'Ngày học\ntháng này'),
                // SỬA LỖI Ở ĐÂY: thay ?? () bằng ?? 0
                _stat('${_calculateBestStreak()}', 'Kỷ lục'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStrip(List<DateTime> weekDays, List<String> labels, List<DateTime> chain, DateTime todayKey) {
    return Card(
      color: Colors.green[100],
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '📅 Tuần này',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[900],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final d = weekDays[i];
                final inStreak = _isInChain(d, chain);
                final isToday = _dayKey(d) == todayKey;

                CalendarDayDTO dayData;
                try {
                  dayData = userActivityController.streakData!.calendarDays.firstWhere(
                        (day) => _dayKey(day.date) == _dayKey(d),
                  );
                } catch (e) {
                  dayData = CalendarDayDTO(
                    date: d,
                    studied: false,
                    minutesStudied: 0,
                    isInCurrentStreak: false,
                  );
                }

                return _calendarDay(
                  labels[i],
                  dayData.studied,
                  inStreak: inStreak,
                  isToday: isToday,
                  minutes: dayData.minutesStudied,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyCalendar(int daysInMonth, int studiedDaysThisMonth, int streakDaysThisMonth, List<DateTime> chain, DateTime todayKey) {
    return Card(
      color: Colors.green[100],
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.purple, size: 20),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  'Tháng ${currentMonth.toString().padLeft(2, '0')} - $currentYear',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[900],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.purple, size: 20),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '✅ Đã học: $studiedDaysThisMonth / $daysInMonth ngày',
              style: TextStyle(
                fontSize: 14,
                color: Colors.purple[800],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (streakDaysThisMonth > 0) ...[
              Text(
                '🔥 Trong chuỗi: $streakDaysThisMonth ngày',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1.2,
              ),
              itemCount: daysInMonth,
              itemBuilder: (_, i) {
                final day = i + 1;
                final date = _dayKey(DateTime(currentYear, currentMonth, day));
                final inStreak = _isInChain(date, chain);
                final isToday = _dayKey(date) == todayKey;

                CalendarDayDTO dayData;
                try {
                  dayData = userActivityController.streakData!.calendarDays.firstWhere(
                        (calendarDay) => _dayKey(calendarDay.date) == _dayKey(date),
                  );
                } catch (e) {
                  dayData = CalendarDayDTO(
                    date: date,
                    studied: false,
                    minutesStudied: 0,
                    isInCurrentStreak: false,
                  );
                }

                return _calendarCell(
                  day: day,
                  studied: dayData.studied,
                  inStreak: inStreak,
                  isToday: isToday,
                  minutes: dayData.minutesStudied,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarDay(String label, bool studied, {
    bool inStreak = false,
    bool isToday = false,
    int minutes = 0
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: studied
                    ? (inStreak ? Colors.orange : Colors.green)
                    : Colors.grey[300],
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: Colors.purple, width: 3)
                    : null,
              ),
              child: studied
                  ? Icon(
                inStreak ? Icons.local_fire_department : Icons.check,
                color: Colors.white,
                size: inStreak ? 20 : 16,
              )
                  : const SizedBox.shrink(),
            ),
            if (minutes > 0 && !inStreak) ...[
              Positioned(
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$minutes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? Colors.purple[900] : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _calendarCell({
    required int day,
    required bool studied,
    bool inStreak = false,
    bool isToday = false,
    int minutes = 0,
  }) {
    return Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: studied
              ? (inStreak ? Colors.orange : Colors.green)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: Colors.purple, width: 2)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
          Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (studied)
              Icon(
                inStreak ? Icons.local_fire_department : Icons.check,
                color: Colors.white,
                size: inStreak ? 20 : 16,
              )
            else
              Text(
                '$day',
                style: TextStyle(
                  color: isToday ? Colors.purple[900] : Colors.black54,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        if (minutes > 0 && !inStreak) ...[
    Positioned(
    top: 2,
    right: 2,
    child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
    decoration: BoxDecoration(
    color: Colors.green[700],
    borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
    '$minutes',
    style: const TextStyle(
    color: Colors.white,
    fontSize: 8,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    ),
    ],
    ],
    ),
    );
  }

  Widget _stat(String value, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF667EEA),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        textAlign: TextAlign.center,
      ),
    ],
  );
}