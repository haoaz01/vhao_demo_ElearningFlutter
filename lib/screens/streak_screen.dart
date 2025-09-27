import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/auth_controller.dart';
import '../controllers/progress_controller.dart';

class StreakScreen extends StatefulWidget {
  final DateTime? overrideNow;
  const StreakScreen({super.key, this.overrideNow});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  late final ProgressController progressController;
  late final AuthController auth;

  late DateTime now;
  Set<DateTime> studyDays = {};

  late int currentMonth;
  late int currentYear;
  late final Worker _statsWorker;

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    progressController = Get.isRegistered<ProgressController>()
        ? Get.find<ProgressController>()
        : Get.put(ProgressController());
    auth = Get.find<AuthController>();

    now = widget.overrideNow ?? DateTime.now();
    currentMonth = now.month;
    currentYear = now.year;

    _init();
    _statsWorker = ever(progressController.statsVersion, (_) => _loadLocalDays());
  }

  Future<void> _init() async {
    // nạp streak từ BE
    await progressController.loadStreak();
    await _loadLocalDays();
  }

  @override
  void dispose() {
    _statsWorker.dispose();
    super.dispose();
  }

  Future<void> _loadLocalDays() async {
    final days = await progressController.readStudyDays();
    setState(() => studyDays = days.map(_dayKey).toSet());
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

  @override
  Widget build(BuildContext context) {
    const primary = Colors.purple;

    final todayKey = _dayKey(now);
    final monday = _dayKey(todayKey.subtract(Duration(days: todayKey.weekday - 1)));
    final weekDays =
    List<DateTime>.generate(7, (i) => _dayKey(monday.add(Duration(days: i))));
    const labels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];

    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
    final learnedDaysThisMonth = studyDays
        .where((d) => d.year == currentYear && d.month == currentMonth)
        .length;

    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        backgroundColor: primary,
        title:
        const Text('🔥 Chuỗi Ngày Học', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // nút “touch” streak hôm nay (gọi BE) rồi reload
          IconButton(
            icon: const Icon(Icons.local_fire_department, color: Colors.white),
            tooltip: 'Chạm tính streak hôm nay',
            onPressed: () async {
              await progressController.loadStreak(); // nếu BE có /touch thì thay bằng touch
              await _loadLocalDays();
            },
          )
        ],
      ),
      body: ListView(
        children: [
          // ===== Header số liệu từ API =====
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(() {
                final loaded = progressController.streakLoaded.value;
                final cur = progressController.currentStreak.value;
                final best = progressController.bestStreak.value;
                final total = progressController.totalDays.value;
                final last = progressController.lastActive.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📈 Thống kê streak',
                        style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('$cur', 'Ngày liên tiếp'),
                        _stat('$total', 'Tổng ngày học'),
                        _stat('$best', 'Kỷ lục'),
                      ],
                    ),
                    if (loaded && last != null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Hoạt động gần nhất: ${DateFormat('dd/MM/yyyy').format(last)}',
                          style: const TextStyle(
                              fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),
          ),

          // ===== Weekly strip =====
          Card(
            color: Colors.purple[100],
            margin: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('📅 Chuỗi ngày tuần này',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[900])),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (i) {
                      final d = weekDays[i];
                      final learned = studyDays.contains(d);
                      final isToday = d == todayKey;
                      return _streakDay(labels[i], learned, isToday: isToday);
                    }),
                  ),
                ],
              ),
            ),
          ),

          // ===== Monthly calendar =====
          Card(
            color: Colors.purple[100],
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.purple),
                        onPressed: () => _changeMonth(-1)),
                    Text('Tháng ${currentMonth.toString().padLeft(2, '0')} - $currentYear',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[900])),
                    IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.purple),
                        onPressed: () => _changeMonth(1)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('✅ Đã học: $learnedDaysThisMonth / $daysInMonth ngày',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple[800],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, crossAxisSpacing: 4, mainAxisSpacing: 4),
                  itemCount: daysInMonth,
                  itemBuilder: (_, i) {
                    final day = i + 1;
                    final date = _dayKey(DateTime(currentYear, currentMonth, day));
                    final learned = studyDays.contains(date);
                    final isToday = date == todayKey;
                    return Container(
                      decoration: BoxDecoration(
                        color: learned ? Colors.orange : Colors.grey[300],
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: Colors.purple, width: 2.5)
                            : null,
                      ),
                      child: Center(
                        child: learned
                            ? const Icon(Icons.local_fire_department,
                            color: Colors.white, size: 18)
                            : Text('$day',
                            style: const TextStyle(
                                color: Colors.black, fontSize: 12)),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakDay(String label, bool learned, {bool isToday = false}) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: learned ? Colors.orange : Colors.grey[300],
            shape: BoxShape.circle,
            border: isToday ? Border.all(color: Colors.purple, width: 3) : null,
          ),
          child: learned
              ? const Icon(Icons.local_fire_department, color: Colors.white, size: 20)
              : const SizedBox.shrink(),
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

  Widget _stat(String value, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF667EEA))),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ],
  );
}
