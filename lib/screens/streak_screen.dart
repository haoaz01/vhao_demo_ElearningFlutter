import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
  late final AuthController s; // nếu không dùng có thể xoá 2 dòng (khai báo + init)

  late DateTime now;
  Set<DateTime> studyDays = {};

  late int currentMonth;
  late int currentYear;
  // late final Worker _statsWorker;

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    streakController = Get.isRegistered<StreakController>()
        ? Get.find<StreakController>()
        : Get.put(StreakController());
    s = Get.find<AuthController>(); // nếu không cần có thể xoá

    now = widget.overrideNow ?? DateTime.now();
    currentMonth = now.month;
    currentYear = now.year;
    streakController.loadStreak();  // alias fetchStreak()
    _init();

    // lắng nghe khi số liệu streak đổi để reload các ngày đã học
    // _statsWorker = ever(streakController.statsVersion, (_) => _loadLocalDays());
  }

  Future<void> _init() async {
    await streakController.loadStreak(); // alias -> fetchStreak()
    await _loadLocalDays();
  }

  @override
  void dispose() {
    // _statsWorker.dispose();
    super.dispose();
  }

  Future<void> _loadLocalDays() async {
    // final days = await streakController.readStudyDays(); // TODO: nối API nếu có
    // setState(() => studyDays = days.map(_dayKey).toSet());
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

  List<DateTime> _buildStreakChain({
    required int currentStreak,
    required DateTime? lastActiveDate,
    DateTime? now,
  }) {
    if (currentStreak <= 0 || lastActiveDate == null) return [];
    final today = DateTime.now();
    DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

    final dToday = day(now ?? today);
    final anchor = day(lastActiveDate);

    if (anchor.isBefore(dToday.subtract(const Duration(days: 1)))) {
      return [];
    }

    final len = currentStreak;
    return List.generate(len, (i) {
      final offset = len - 1 - i;
      final d = anchor.subtract(Duration(days: offset));
      return day(d);
    });
  }

  bool _isInChain(DateTime d, List<DateTime> chain) {
    final key = _dayKey(d);
    return chain.any((c) => _dayKey(c) == key);
  }

  List<DateTime> _currentChain() {
    return _buildStreakChain(
      currentStreak: streakController.currentStreak.value,
      lastActiveDate: streakController.lastActive.value,
      now: widget.overrideNow,
    );
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
          IconButton(
            icon: const Icon(Icons.local_fire_department, color: Colors.white),
            tooltip: 'Chạm tính streak hôm nay',
            onPressed: () async {
              await streakController.touch(); // alias -> checkInToday()
              await streakController.loadStreak();
              await _loadLocalDays();
            },
          )
        ],
      ),
      body: ListView(
        children: [
          // ===== Strip ngang =====
          Obx(() {
            final chain = _currentChain();
            if (chain.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    'Chưa có chuỗi hoạt động gần đây',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: chain.map((d) {
                  final isToday = _dayKey(d) == todayKey;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday ? Border.all(color: Colors.green, width: 2) : null,
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Text("${d.day}/${d.month}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              ),
            );
          }),

          // ===== Header số liệu =====
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(() {
                final loaded = streakController.streakLoaded.value;
                final cur = streakController.currentStreak.value;
                final best = streakController.bestStreak.value;
                final total = streakController.totalDays.value;
                final last = streakController.lastActive.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📈 Thống kê streak',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),
          ),

          // ===== Weekly strip =====
          Obx(() {
            final chain = _currentChain();
            return Card(
              color: Colors.green[100],
              margin: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('📅 Chuỗi ngày tuần này',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple[900])),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (i) {
                        final d = weekDays[i];
                        final learned = _isInChain(d, chain);
                        return _streakDay(labels[i], learned, isToday: d == todayKey);
                      }),
                    ),
                  ],
                ),
              ),
            );
          }),

          // ===== Monthly calendar =====
          Obx(() {
            final chain = _currentChain();
            final learnedDaysThisMonth = List.generate(daysInMonth, (i) => i + 1)
                .where((day) => _isInChain(DateTime(currentYear, currentMonth, day), chain))
                .length;
            return Card(
              color: Colors.green[100],
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
                              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple[900])),
                      IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.purple),
                          onPressed: () => _changeMonth(1)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('✅ Đã học: $learnedDaysThisMonth / $daysInMonth ngày',
                      style: TextStyle(
                          fontSize: 14, color: Colors.purple[800], fontWeight: FontWeight.w500)),
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
                      final learned = _isInChain(date, chain);
                      final isToday = date == todayKey;
                      return Container(
                        decoration: BoxDecoration(
                          color: learned ? Colors.orange : Colors.grey[300],
                          shape: BoxShape.circle,
                          border: isToday ? Border.all(color: Colors.green, width: 2.5) : null,
                        ),
                        child: Center(
                          child: learned
                              ? const Icon(Icons.local_fire_department, color: Colors.white, size: 18)
                              : Text('$day',
                              style: const TextStyle(color: Colors.black, fontSize: 12)),
                        ),
                      );
                    },
                  ),
                ]),
              ),
            );
          }),
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
            border: isToday ? Border.all(color: Colors.green, width: 3) : null,
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
