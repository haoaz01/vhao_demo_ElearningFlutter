import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/auth_controller.dart';
import '../controllers/user_activity_controller.dart';
import '../controllers/quiz_history_controller.dart';
import '../controllers/progress_controller.dart';

class HomeTopSummary extends StatefulWidget {
  const HomeTopSummary({super.key});

  @override
  State<HomeTopSummary> createState() => _HomeTopSummaryState();
}

class _HomeTopSummaryState extends State<HomeTopSummary> {
  late final AuthController auth;
  late final UserActivityController uac;
  late final QuizHistoryController qc;
  late final ProgressController pc;

  // Breakpoints & UI constants
  static const double _gutter = 12; // khoảng cách giữa các card
  static const double _minAspect = 1.55; // card rộng:cao tối thiểu
  static const double _maxAspect = 1.85; // card rộng:cao tối đa

  @override
  void initState() {
    super.initState();
    auth = Get.find<AuthController>();
    uac  = Get.find<UserActivityController>();
    qc   = Get.find<QuizHistoryController>();
    pc   = Get.find<ProgressController>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = auth.userId.value;
      await uac.ensureAutoSessionStarted(uid);
      uac.refreshData(uid);
      qc.loadDailyStats(days: 7);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isUltraCompact = size.width < 340 || size.height < 640;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // Kích thước card theo hàng ngang:
        // - Nếu đủ rộng: 3 card vừa khít -> không cần cuộn
        // - Nếu hẹp: mỗi card tối thiểu 150~180 -> tự cuộn ngang
        const double spacing = 12; // khoảng cách giữa các card
        final double idealCardWidth = (w - 2 * spacing) / 3; // width để đủ 3 thẻ
        final double cardWidth = idealCardWidth.clamp(160.0, 220.0); // kẹp cho đẹp
        // aspect ratio linh hoạt (rộng/cao)
        final double desiredAspect = (cardWidth / 180).clamp(_minAspect, _maxAspect);
        final double cardHeight = cardWidth / desiredAspect;

        // Tổng chiều rộng thực tế của dãy 3 card (để quyết định có cần cuộn)
        final double totalRowWidth = cardWidth * 3 + spacing * 2;

        return SizedBox(
          height: cardHeight + 24.w, // cộng thêm chút padding vertical
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: ConstrainedBox(
                // Nếu đủ chỗ, ép hàng ngang đúng = width container -> không cuộn
                // Nếu thiếu chỗ, để nguyên totalRowWidth -> sẽ cuộn ngang
                constraints: BoxConstraints(
                  minWidth: totalRowWidth < w ? w - 24.w /*trừ padding*/ : totalRowWidth,
                ),
                child: Row(
                  mainAxisAlignment: totalRowWidth < w
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: _quizCard(),
                    ),
                    SizedBox(width: spacing.w),
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: _theoryCard(),
                    ),
                    SizedBox(width: spacing.w),
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: _streakCard(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- Card Quiz ----------------
  Widget _quizCard() {
    return Obx(() {
      final list = qc.quizDaily.toList(growable: false);
      double? avg;
      if (list.isNotEmpty) {
        final active = list.where((e) => e.totalSum > 0).toList();
        if (active.isNotEmpty) {
          avg = active
              .map((e) => e.percentAccuracy)
              .reduce((a, b) => a + b) /
              active.length;
        }
      }
      final display = avg == null ? '--' : '${avg.toStringAsFixed(0)}%';
      return _summaryCard(
        title: 'Quiz',
        value: display,
        icon: Icons.quiz,
        color: Colors.blue,
        subtitle: 'Điểm đúng trung bình',
      );
    });
  }

  // --------------- Card Lý thuyết ---------------
  Widget _theoryCard() {
    return Obx(() {
      final classStr = auth.selectedClass.value;
      if (classStr.isEmpty) {
        return _summaryCard(
          title: 'Lý thuyết',
          value: '--',
          icon: Icons.menu_book_rounded,
          color: Colors.purple,
          subtitle: 'Chưa chọn khối',
        );
      }
      final grade = int.tryParse(classStr) ?? 0;
      final list = pc.progressList.where((p) => p.grade == grade).toList();
      if (list.isEmpty) {
        return _summaryCard(
          title: 'Lý thuyết',
          value: '--',
          icon: Icons.menu_book_rounded,
          color: Colors.purple,
          subtitle: 'Chưa có tiến độ',
        );
      }
      final avg = list
          .map((p) => p.progressPercent)
          .fold<double>(0, (a, b) => a + b) /
          list.length;
      return _summaryCard(
        title: '% Lý thuyết',
        value: '${avg.toStringAsFixed(0)}%',
        icon: Icons.menu_book_rounded,
        color: Colors.purple,
        subtitle: 'Hoàn thành trung bình',
      );
    });
  }

  // ---------------- Card Streak ----------------
  Widget _streakCard() {
    return GetBuilder<UserActivityController>(
      builder: (c) {
        final todayMin = c.todayTotalMinutes;
        final done = c.isTodayTargetAchieved;

        return _surface(
          color: Colors.green.withOpacity(0.1),
          shadowColor: Colors.green.withOpacity(0.25),
          child: _streakContent(todayMin, done, c.remainingMinutes),
        );
      },
    );
  }

  // NEW: Content Streak tự scale theo chiều rộng available của card bằng LayoutBuilder
  Widget _streakContent(int todayMin, bool done, int remaining) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // Typography theo width của card (không dùng .sp để tránh double-scale)
        final double titleSize  = (w * 0.075).clamp(12, 16);
        final double mainSize   = (w * 0.14).clamp(16, 24);
        final double chipSize   = (w * 0.055).clamp(10, 13);
        final double iconSize   = (w * 0.075).clamp(18, 22);

        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: done ? Colors.orange : Colors.grey,
                    size: iconSize,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Streak hôm nay',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                '$todayMin/15p',
                style: TextStyle(
                  fontSize: mainSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: done ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  done ? 'Đã hoàn thành' : '${remaining}p còn lại',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: chipSize,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------- Card chuẩn dùng chung ----------------
  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return _surface(
      color: color.withOpacity(0.1),
      shadowColor: color.withOpacity(0.25),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          // Typography theo width card (tránh dùng .sp ở đây để không double-scale)
          final double titleSize  = (w * 0.07).clamp(12, 16);
          final double valueSize  = (w * 0.12).clamp(18, 24);
          final double subSize    = (w * 0.05).clamp(10, 13);
          final double iconSize   = (w * 0.075).clamp(18, 22);

          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: iconSize),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: subSize,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // --------------- Surface (nền + bóng) tái sử dụng ----------------
  Widget _surface({
    required Color color,
    required Color shadowColor,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
