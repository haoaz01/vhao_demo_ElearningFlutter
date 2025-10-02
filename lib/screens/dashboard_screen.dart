import 'package:get/get.dart' hide Progress;
import 'package:flutter/material.dart';
import 'package:flutter_elearning_application/model/progress_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/progress_controller.dart';
import '../controllers/quiz_history_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_activity_controller.dart';
import '../repositories/user_activity_repository.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/progress_repository.dart';
import 'dart:convert';
import 'streak_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  Timer? _midnightTimer;

  final ProgressController progressController = Get.find<ProgressController>();
  final AuthController authController = Get.find<AuthController>();
  final QuizHistoryController quizHistoryController =
  Get.find<QuizHistoryController>();
  late final UserActivityController userActivityController;

  final Map<String, String> subjectIcons = const {
    'Toán': 'assets/icon/toan.png',
    'Khoa Học Tự Nhiên': 'assets/icon/khoahoctunhien.png',
    'Ngữ Văn': 'assets/icon/nguvan.png',
    'Tiếng Anh': 'assets/icon/tienganh.png',
  };

  final Map<String, Color> subjectColors = const {
    'Toán': Colors.blue,
    'Khoa Học Tự Nhiên': Colors.green,
    'Ngữ Văn': Colors.orange,
    'Tiếng Anh': Colors.purple,
  };

  final List<Map<String, dynamic>> defaultSubjects = const [
    {'name': 'Toán', 'code': 'toan'},
    {'name': 'Khoa Học Tự Nhiên', 'code': 'khoahoctunhien'},
    {'name': 'Ngữ Văn', 'code': 'nguvan'},
    {'name': 'Tiếng Anh', 'code': 'tienganh'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // KHỞI TẠO CONTROLLER TRƯỚC
    userActivityController = Get.isRegistered<UserActivityController>()
        ? Get.find<UserActivityController>()
        : Get.put(
      UserActivityController(
        repository: UserActivityRepository(client: Get.find()),
      ),
      permanent: true,
    );

    // Chạy sau frame đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
          final userId = authController.userId.value;
          userActivityController.ensureAutoSessionStarted(userId);
          _loadProgressData();
        });

    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      userActivityController
          .ensureAutoSessionStarted(authController.userId.value);
      _loadProgressData();
    } else if (state == AppLifecycleState.paused) {
      userActivityController.persistSessionSnapshot(); // không await
    }
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);

    _midnightTimer = Timer(diff + const Duration(seconds: 1), () async {
      await userActivityController.persistSessionSnapshot(); // snapshot lần cuối
      await _loadProgressData();
      _scheduleMidnightRefresh(); // lên lịch lại cho ngày tiếp theo
    });
  }

  Future<void> _loadProgressData() async {
    await userActivityController.fetchStreakInfo(authController.userId.value);
    await userActivityController.fetchTodayInfo(authController.userId.value);
    await userActivityController.fetchStreakCalendar(  // 👈 THÊM DÒNG NÀY
      authController.userId.value,
      months: 1,
    );
    await quizHistoryController.loadDailyStats(days: 7);

  }

  Future<void> _testApiConnection() async {
    final auth = Get.find<AuthController>();
    final repo = UserActivityRepository(client: http.Client());
    final result = await repo.testConnectionDetailed(userId: auth.userId.value);

    debugPrint("🔍 API test result: $result");
  }

  Color _getSubjectColor(String subjectName) {
    return subjectColors[subjectName] ?? Colors.grey;
  }

  String _getSubjectIcon(String subjectName) {
    return subjectIcons[subjectName] ?? 'assets/icon/default.png';
  }

  List<Map<String, dynamic>> _getDisplaySubjects() {
    final currentGrade = authController.selectedClass.value.isEmpty
        ? 0
        : int.tryParse(authController.selectedClass.value) ?? 0;

    if (currentGrade == 0) return [];

    final progressMap = <String, Progress>{};
    for (var progress in progressController.progressList) {
      if (progress.grade == currentGrade) {
        progressMap[progress.subjectCode] = progress;
      }
    }

    return defaultSubjects.map((subject) {
      final subjectCode = subject['code'] as String;
      final progress = progressMap[subjectCode];

      return {
        'name': subject['name'],
        'code': subjectCode,
        'grade': currentGrade,
        'completedLessons': progress?.completedLessons ?? 0,
        'totalLessons': progress?.totalLessons ?? 0,
        'progressPercent': progress?.progressPercent ?? 0.0,
        'hasProgress': progress != null,
      };
    }).toList();
  }

  double _calculateOverallProgress(List<Map<String, dynamic>> displaySubjects) {
    if (displaySubjects.isEmpty) return 0.0;
    double totalPercent = 0.0;
    for (var subject in displaySubjects) {
      totalPercent += (subject['progressPercent'] as double);
    }
    return totalPercent / displaySubjects.length;
  }

  // ====== CARD MÔN HỌC (đã responsive cho máy nhỏ) ======
  Widget _buildSubjectCard(
      String subjectName,
      String subjectCode,
      int grade,
      int completedLessons,
      int totalLessons,
      double progressPercent,
      bool hasProgress, {
        bool compact = false,
      }) {
    final color = _getSubjectColor(subjectName);
    final iconPath = _getSubjectIcon(subjectName);

    // Kích thước khi compact
    final double buttonH   = compact ? 34.h : 40.h;
    final EdgeInsets btnPad = EdgeInsets.symmetric(
      horizontal: compact ? 10.w : 16.w,
      vertical: compact ? 6.h  : 10.h,
    );
    final double titleFs   = compact ? 14.sp : 16.sp;
    final double subFs     = compact ? 10.sp : 12.sp;
    final double labelFs   = compact ? 12.sp : 14.sp;

// giảm khoảng cách & chiều cao progress khi compact
    final double vGapHeader = compact ? 10.h : 16.h;
    final double vGapSmall  = compact ? 6.h  : 8.h;
    final double progressH  = compact ? 6.h  : 8.h;

    return Container(
      margin: EdgeInsets.only(left: 16.w),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                children: [
                  Container(
                    width: compact ? 34.w : 40.w,
                    height: compact ? 34.h : 40.h,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Center(
                      child: Image.asset(iconPath, width: 22.w, height: 22.h),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleFs,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Khối $grade',
                          style: TextStyle(fontSize: subFs, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: vGapHeader),

              // --- Tiến độ ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiến độ',
                    style: TextStyle(
                      fontSize: compact ? 13.sp : 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '$completedLessons/$totalLessons bài',
                    style: TextStyle(fontSize: subFs, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: vGapSmall),
              Container(
                height: progressH,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final ratio = (progressPercent.clamp(0, 100)) / 100.0;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: constraints.maxWidth * ratio,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: vGapSmall),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${progressPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: subFs,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),

              // Đệm ít thôi ở máy nhỏ
              SizedBox(height: compact ? 8.h : 12.h),

              // --- Nút: cố định chiều cao để không “chòi” ra ngoài ---
              SizedBox(
                height: buttonH,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToSubject(subjectName, grade, subjectCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: btnPad,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      hasProgress ? 'Tiếp tục học' : 'Bắt đầu học',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: labelFs, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSubject(String subjectName, int grade, String subjectCode) {
    Get.toNamed('/theory', arguments: {
      'subject': subjectName,
      'grade': grade,
      'subjectCode': subjectCode,
    });
  }

  void _navigateToStreakScreen() {
    Get.to(() => const StreakScreen());
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2.w,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 16.h),
          Text(
            'Đang tải dữ liệu...',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoClassSelectedState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 80.sp, color: Colors.grey[300]),
            SizedBox(height: 24.h),
            Text(
              'Chưa chọn khối lớp',
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'Vui lòng chọn khối lớp trong phần Profile để xem tiến trình học tập.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () => Get.toNamed('/profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              ),
              child: Text('Đến Profile', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displaySubjects = _getDisplaySubjects();
    final overallProgress = _calculateOverallProgress(displaySubjects);
    final currentGrade = authController.selectedClass.value.isEmpty
        ? 'Tất cả'
        : 'Khối ${authController.selectedClass.value}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 22.sp),
            onPressed: () async {
              await _loadProgressData();
            },            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: MediaQuery(
        // chặn text-scale quá lớn làm bể layout
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.10),
          ),
        ),
        child: Obx(() {
          if (progressController.isLoading.value) {
            return _buildLoadingState();
          }
          if (authController.selectedClass.value.isEmpty) {
            return _buildNoClassSelectedState();
          }

          return Padding(
            padding: EdgeInsets.all(16.w),
            child: ListView(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, ${authController.username.value}!',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Tiến trình học tập của bạn ($currentGrade)',
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Streak
                GestureDetector(
                  onTap: _navigateToStreakScreen,
                  child: const _StreakCardNew(),
                ),
                SizedBox(height: 16.h),

                // Quiz history
                const _QuizHistoryFromApi(),
                SizedBox(height: 16.h),

                // Tổng tiến độ
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                          child: const Icon(Icons.auto_graph_rounded,
                              size: 24, color: Colors.blue),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tổng tiến độ',
                                  style: TextStyle(
                                      fontSize: 14.sp, color: Colors.grey[600])),
                              SizedBox(height: 4.h),
                              const Text(
                                // giữ font tĩnh cho con số
                                '',
                                style: TextStyle(fontSize: 0),
                              ),
                              Text(
                                '${overallProgress.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(
                            '${displaySubjects.length} môn',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Header list môn
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Môn học ($currentGrade)',
                      style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${displaySubjects.length} môn',
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // List card môn học (responsive)
                SizedBox(
                  height: (MediaQuery.of(context).size.height * 0.30)
                      .clamp(220.0, 280.0), // trước là 200–260
                  child: LayoutBuilder(
                    builder: (ctx, cst) {
                      final w = cst.maxWidth;
                      final bool compact = w < 370;   // ⬅ nới điều kiện compact (máy hẹp hơn dễ vào chế độ gọn)
                      final double cardW = (w * 0.72).clamp(200.0, 320.0);

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: displaySubjects.length,
                        padding: EdgeInsets.only(right: 16.w),
                        itemBuilder: (context, index) {
                          final subject = displaySubjects[index];
                          return SizedBox(
                            width: cardW,
                            child: _buildSubjectCard(
                              subject['name'] as String,
                              subject['code'] as String,
                              subject['grade'] as int,
                              subject['completedLessons'] as int,
                              subject['totalLessons'] as int,
                              subject['progressPercent'] as double,
                              subject['hasProgress'] as bool,
                              compact: compact,        // ⬅ truyền cờ compact
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// =================== WIDGETS PHỤ ===================

class _StreakCardNew extends StatelessWidget {
  const _StreakCardNew();

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final uid = authController.userId.value;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GetBuilder<UserActivityController>(
          builder: (controller) {
            // ⚡️ Di chuyển logic check vào đây
            if (controller.streakCalendar == null &&
                !controller.isLoadingCalendar) {
              controller.fetchStreakCalendar(uid, months: 1);
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.isLoading && controller.streakInfo == null) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.error != null) {
              return Column(
                children: [
                  const Icon(Icons.error_outline, size: 32, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Lỗi tải dữ liệu streak',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => controller
                        .fetchStreakInfo(authController.userId.value),
                    child: const Text('Thử lại'),
                  ),
                ],
              );
            }

            // Dữ liệu hiển thị
            final todayMinutes = controller.todayTotalMinutes;
            final currentStreak = controller.currentStreak;
            final todayStudied = controller.isTodayTargetAchieved;
            final remainingMinutes = controller.remainingMinutes;
            final progress = controller.todayProgressSeconds;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        color:
                        currentStreak > 0 ? Colors.orange : Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Chuỗi ngày học liên tiếp',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: currentStreak > 0
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tiến trình hôm nay
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hôm nay',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '$todayMinutes',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text('/15 phút',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600])),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(
                            todayStudied
                                ? 'Đã hoàn thành'
                                : todayMinutes > 0
                                ? 'Đang học'
                                : 'Chưa học',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: todayStudied
                              ? Colors.green
                              : todayMinutes > 0
                              ? Colors.orange
                              : Colors.grey,
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: todayStudied ? Colors.green : Colors.orange,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$todayMinutes phút',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        Text('$remainingMinutes phút còn lại',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

                // 3 số liệu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StreakStatChipNew(
                      value: '$currentStreak',
                      label: 'Ngày liên tiếp',
                      color: currentStreak > 0 ? Colors.orange : Colors.grey,
                    ),
                    _StreakStatChipNew(
                      value: controller.streakCalendar?.calendarDays
                          .where((d) => d.studied)
                          .length
                          .toString() ??
                          '0',
                      label: 'Tổng ngày học',
                      color: Colors.blue,
                    ),
                    _StreakStatChipNew(
                      value: '$currentStreak',
                      label: 'Kỷ lục',
                      color: Colors.purple,
                    ),
                  ],
                ),

                if (controller.streakCalendar?.streakEndDate != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Hoạt động gần nhất: ${DateFormat('dd/MM/yyyy').format(controller.streakCalendar!.streakEndDate!)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
class _StreakStatChipNew extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StreakStatChipNew({
    required this.value,
    required this.label,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _QuizHistoryFromApi extends StatelessWidget {
  // Giữ lại tham số cho khỏi phải sửa nơi gọi, nhưng không dùng nữa

  const _QuizHistoryFromApi({ super.key });

  @override
  Widget build(BuildContext context) {
    final qc = Get.find<QuizHistoryController>();

    return Obx(() {
      if (qc.isQuizLoading.value) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      final list = qc.quizDaily.toList(growable: false);
      if (list.isEmpty) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Chưa có dữ liệu quiz trong thời gian gần đây'),
          ),
        );
      }

      // Tính trung bình cộng như cũ: chỉ tính ngày có dữ liệu (totalSum > 0)
      final active = list.where((e) => e.totalSum > 0).toList();
      final avg = active.isEmpty
          ? 0.0
          : active
          .map((e) => e.percentAccuracy)
          .reduce((a, b) => a + b) /
          active.length;

      final days = list.map((e) => e.day).toList();
      final percents = list.map((e) => e.percentAccuracy).toList();

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lịch sử Quiz (tỉ lệ đúng %)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // 🔙 Hiển thị một dòng duy nhất như cũ
              Text(
                'Điểm trung bình: ${avg.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),
              SizedBox(
                height: 260,
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: 105,
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(horizontalLines: [
                      HorizontalLine(
                        y: 100,
                        dashArray: [6, 4],
                        strokeWidth: 1,
                        color: Colors.grey.withOpacity(0.6),
                      ),
                    ]),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBorderRadius: BorderRadius.circular(6),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final pct = rod.toY.clamp(0, 100).toStringAsFixed(0);
                          return BarTooltipItem(
                            '$pct%',
                            const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          interval: 20,
                          getTitlesWidget: (value, _) {
                            if (value > 100) return const SizedBox.shrink();
                            return Text('${value.toInt()}%');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22, // thấp hơn
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                            return SizedBox(
                              width: 24, // ô hẹp lại
                              child: Center(
                                child: Text(
                                  DateFormat('dd/MM').format(days[idx]),
                                  style: const TextStyle(fontSize: 10), // nhỏ lại
                                  overflow: TextOverflow.visible,
                                  softWrap: false,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      checkToShowHorizontalLine: (value) =>
                      value % 20 == 0 && value <= 100,
                    ),
                    barGroups: List.generate(days.length, (i) {
                      final toY = percents[i];
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: toY,
                            width: 14,
                            color: Colors.blue,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
