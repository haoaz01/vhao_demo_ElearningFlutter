import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../model/calendar_day.dart';

import '../controllers/auth_controller.dart';
import '../controllers/streak_controller.dart';


class StreakScreen extends StatefulWidget {
  final DateTime? overrideNow;
  const StreakScreen({super.key, this.overrideNow});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}


class _StreakScreenState extends State<StreakScreen> {
  late final StreakController streakController;
  late final AuthController authController;

  late DateTime now;
  late int currentMonth;
  late int currentYear;

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    streakController = Get.isRegistered<StreakController>()
        ? Get.find<StreakController>()
        : Get.put(StreakController());
    authController = Get.find<AuthController>();

    now = widget.overrideNow ?? DateTime.now();
    currentMonth = now.month;
    currentYear = now.year;

    _init();
  }

  Future<void> _init() async {
    await streakController.fetchStreak();
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
    return streakController.streakDays.map(_dayKey).toList();
  }

  bool _isInChain(DateTime d, List<DateTime> chain) {
    final key = _dayKey(d);
    return chain.any((c) => _dayKey(c) == key);
  }

  // Lấy số ngày học trong tháng hiện tại (cả những ngày không trong streak nhưng học trên 15 phút)
  int _getStudiedDaysInMonth() {
    final monthDays = streakController.getCalendarForMonth(currentYear, currentMonth);
    return monthDays.where((day) => day.studied).length;
  }

  // Lấy số ngày trong streak trong tháng hiện tại
  int _getStreakDaysInMonth() {
    final monthDays = streakController.getCalendarForMonth(currentYear, currentMonth);
    return monthDays.where((day) => day.isInCurrentStreak).length;
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
          // Hiển thị tiến trình hôm nay
          Obx(() => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${streakController.todayMinutes.value}p',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '/15p',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )),
          IconButton(
            icon: const Icon(Icons.local_fire_department, color: Colors.white),
            tooltip: 'Chạm tính streak hôm nay',
            onPressed: () async {
              await streakController.touch();
              setState(() {});
            },
          )
        ],
      ),
      body: Obx(() {
        if (!streakController.streakLoaded.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final chain = _currentChain();
        final studiedDaysThisMonth = _getStudiedDaysInMonth();
        final streakDaysThisMonth = _getStreakDaysInMonth();

        return ListView(
          children: [
            // ===== Tiến trình hôm nay =====
            Card(
              margin: const EdgeInsets.all(12),
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
                          backgroundColor: streakController.todayStudied.value
                              ? Colors.green
                              : Colors.orange,
                          label: Text(
                            streakController.todayStudied.value ? 'Đã hoàn thành' : 'Chưa hoàn thành',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: streakController.todayProgress / 100,
                      backgroundColor: Colors.grey[300],
                      color: Colors.green,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${streakController.todayMinutes.value} phút',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${streakController.remainingMinutes} phút còn lại',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ===== Strip ngang streak =====
            if (chain.isNotEmpty) ...[
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12),
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: chain.map((d) {
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
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ===== Header số liệu =====
            Card(
              margin: const EdgeInsets.all(12),
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
                        _stat('${streakController.currentStreak.value}', 'Ngày liên tiếp'),
                        _stat('$studiedDaysThisMonth', 'Ngày học\ntháng này'),
                        _stat('${streakController.bestStreak.value}', 'Kỷ lục'),
                      ],
                    ),
                    if (streakController.lastActive.value != null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Hoạt động gần nhất: ${DateFormat('dd/MM/yyyy').format(streakController.lastActive.value!)}',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ===== Weekly strip =====
            Card(
              color: Colors.green[100],
              margin: const EdgeInsets.symmetric(horizontal: 12),
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
                        final isToday = d == todayKey;
                        final dayData = streakController.calendarDays.firstWhere(
                              (day) => _dayKey(day.date) == d,
                          orElse: () => CalendarDay(
                            date: d,
                            studied: false,
                            minutesStudied: 0,
                            isInCurrentStreak: false,
                          ),
                        );

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
            ),

            // ===== Monthly calendar =====
            Card(
              color: Colors.green[100],
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.purple),
                            onPressed: () => _changeMonth(-1),
                          ),
                          Text(
                            'Tháng ${currentMonth.toString().padLeft(2, '0')} - $currentYear',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[900],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, color: Colors.purple),
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
                          final isToday = date == todayKey;
                          final dayData = streakController.calendarDays.firstWhere(
                                (calendarDay) => _dayKey(calendarDay.date) == date,
                            orElse: () => CalendarDay(
                              date: date,
                              studied: false,
                              minutesStudied: 0,
                              isInCurrentStreak: false,
                            ),
                          );

                          return _calendarCell(
                            day: day,
                            studied: dayData.studied,
                            inStreak: inStreak,
                            isToday: isToday,
                            minutes: dayData.minutesStudied,
                          );
                        },
                      ),
                    ]),
              ),
            ),
          ],
        );
      }),
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