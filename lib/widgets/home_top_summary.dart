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

  // tăng nhẹ để tránh overflow trên vài máy DPI cao
  final double _cardHeight = 108;

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
    final h = _cardHeight.h;
    return SizedBox(
      height: h,
      child: Row(
        children: [
          Expanded(child: _quizCard(h)),
          SizedBox(width: 10.w),
          Expanded(child: _theoryCard(h)),
          SizedBox(width: 10.w),
          Expanded(child: _streakCard(h)),
        ],
      ),
    );
  }

  // ---------------- Card Quiz ----------------
  Widget _quizCard(double h) {
    return Obx(() {
      final list = qc.quizDaily.toList(growable: false);
      double? avg;
      if (list.isNotEmpty) {
        final active = list.where((e) => e.totalSum > 0).toList();
        if (active.isNotEmpty) {
          avg = active.map((e) => e.percentAccuracy).reduce((a, b) => a + b) / active.length;
        }
      }
      final display = avg == null ? '--' : '${avg.toStringAsFixed(0)}%';
      return _summaryCard(
        height: h,
        title: 'Quiz',
        value: display,
        icon: Icons.quiz,
        color: Colors.blue,
        subtitle: 'Điểm đúng trung bình',
      );
    });
  }

  // --------------- Card Lý thuyết ---------------
  Widget _theoryCard(double h) {
    return Obx(() {
      final classStr = auth.selectedClass.value;
      if (classStr.isEmpty) {
        return _summaryCard(
          height: h,
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
          height: h,
          title: 'Lý thuyết',
          value: '--',
          icon: Icons.menu_book_rounded,
          color: Colors.purple,
          subtitle: 'Chưa có tiến độ',
        );
      }
      final avg = list.map((p) => p.progressPercent).fold<double>(0, (a, b) => a + b) / list.length;
      return _summaryCard(
        height: h,
        title: '% Lý thuyết',
        value: '${avg.toStringAsFixed(0)}%',
        icon: Icons.menu_book_rounded,
        color: Colors.purple,
        subtitle: 'Hoàn thành trung bình',
      );
    });
  }

  // ---------------- Card Streak (không thanh tiến trình, chữ to hơn) ----------------
  Widget _streakCard(double h) {
    return GetBuilder<UserActivityController>(
      builder: (c) {
        final todayMin = c.todayTotalMinutes;
        final done = c.isTodayTargetAchieved;

        return SizedBox(
          height: h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.r),
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FittedBox(
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
                          size: 20.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Streak hôm nay',
                          style: TextStyle(
                            fontSize: 12.sp,
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
                        fontSize: 20.sp,              // chữ chính to hơn
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
                        done ? 'Đã hoàn thành' : '${c.remainingMinutes}p còn lại',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  // --------------- Card chuẩn dùng chung ----------------
  Widget _summaryCard({
    required double height,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20.sp),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: color),
                ),
                SizedBox(height: 2.h),
                Text(
                  title,
                  style: TextStyle(fontSize: 11.sp, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 9.sp, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
