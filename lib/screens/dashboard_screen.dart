import 'package:flutter/material.dart';
import 'package:flutter_elearning_application/model/progress_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Progress;
import '../controllers/progress_controller.dart';
import '../controllers/auth_controller.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// Thêm import cho StreakScreen
import 'streak_screen.dart'; // Đảm bảo đường dẫn này đúng với project của bạn

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProgressController progressController = Get.find<ProgressController>();
  final AuthController authController = Get.find<AuthController>();

  final Map<String, String> subjectIcons = {
    'Toán': 'assets/icon/toan.png',
    'Khoa Học Tự Nhiên': 'assets/icon/khoahoctunhien.png',
    'Ngữ Văn': 'assets/icon/nguvan.png',
    'Tiếng Anh': 'assets/icon/tienganh.png',
  };

  final Map<String, Color> subjectColors = {
    'Toán': Colors.blue,
    'Khoa Học Tự Nhiên': Colors.green,
    'Ngữ Văn': Colors.orange,
    'Tiếng Anh': Colors.purple,
  };

  // Danh sách các môn học mặc định theo khối lớp
  final List<Map<String, dynamic>> defaultSubjects = [
    {'name': 'Toán', 'code': 'toan'},
    {'name': 'Khoa Học Tự Nhiên', 'code': 'khoahoctunhien'},
    {'name': 'Ngữ Văn', 'code': 'nguvan'},
    {'name': 'Tiếng Anh', 'code': 'tienganh'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProgressData();
    final pc = Get.find<ProgressController>();
    pc.loadStreak();
  }

  Future<void> _loadProgressData() async {
    await progressController.fetchProgressByUser();
  }

  // Get color for subject
  Color _getSubjectColor(String subjectName) {
    return subjectColors[subjectName] ?? Colors.grey;
  }

  // Get icon path for subject
  String _getSubjectIcon(String subjectName) {
    return subjectIcons[subjectName] ?? 'assets/icon/default.png';
  }

  // Tạo danh sách môn học để hiển thị (kết hợp progress thực tế + môn học mặc định)
  List<Map<String, dynamic>> _getDisplaySubjects() {
    final currentGrade = authController.selectedClass.value.isEmpty
        ? 0
        : int.tryParse(authController.selectedClass.value) ?? 0;

    // Nếu chưa chọn lớp, trả về danh sách rỗng
    if (currentGrade == 0) {
      return [];
    }

    // Tạo map từ progress để dễ tra cứu
    final progressMap = <String, Progress>{};
    for (var progress in progressController.progressList) {
      if (progress.grade == currentGrade) {
        progressMap[progress.subjectCode] = progress;
      }
    }

    // Tạo danh sách hiển thị: kết hợp môn học mặc định với progress thực tế
    return defaultSubjects.map((subject) {
      final subjectCode = subject['code'];
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

  // Tính tổng tiến độ cho các môn đã lọc
  double _calculateOverallProgress(List<Map<String, dynamic>> displaySubjects) {
    if (displaySubjects.isEmpty) return 0.0;

    double totalPercent = 0.0;
    int count = 0;

    for (var subject in displaySubjects) {
      totalPercent += subject['progressPercent'];
      count++;
    }

    return count > 0 ? totalPercent / count : 0.0;
  }

  Widget _buildSubjectCard(String subjectName, String subjectCode, int grade,
      int completedLessons, int totalLessons, double progressPercent, bool hasProgress) {
    final color = _getSubjectColor(subjectName);
    final iconPath = _getSubjectIcon(subjectName);

    return Container(
      width: 280.w,
      margin: EdgeInsets.only(right: 16.w),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject Header with Icon
              Row(
                children: [
                  // Icon Container với background color
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Center(
                      child: Image.asset(
                        iconPath,
                        width: 24.w,
                        height: 24.h,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Subject Name and Grade
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Khối $grade',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Progress Information
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiến độ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '${completedLessons}/$totalLessons bài',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8.h),

              // Progress Bar
              Container(
                height: 8.h,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Stack(
                  children: [
                    // Background
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    // Progress
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          width: constraints.maxWidth * (progressPercent / 100),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8.h),

              // Progress Percentage
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${progressPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Continue Button
              ElevatedButton(
                onPressed: () {
                  _navigateToSubject(subjectName, grade, subjectCode);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 40.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  hasProgress ? 'Tiếp tục học' : 'Bắt đầu học',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
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

  // Hàm chuyển đến Streak Screen
  void _navigateToStreakScreen() {
    Get.to(() => StreakScreen());
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2.w,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
            Icon(
              Icons.class_outlined,
              size: 80.sp,
              color: Colors.grey[300],
            ),
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
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () {
                Get.toNamed('/profile');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              ),
              child: Text(
                'Đến Profile',
                style: TextStyle(fontSize: 14.sp),
              ),
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
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 22.sp),
            onPressed: _loadProgressData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Obx(() {
        if (progressController.isLoading.value) {
          return _buildLoadingState();
        }

        // Nếu chưa chọn lớp
        if (authController.selectedClass.value.isEmpty) {
          return _buildNoClassSelectedState();
        }

        return Padding(
          padding: EdgeInsets.all(16.w),
          child: ListView(
            children: [
              // Welcome Section
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
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Streak Card với chức năng chuyển trang
              GestureDetector(
                onTap: _navigateToStreakScreen,
                child: const _StreakCardFromApi(),
              ),
              SizedBox(height: 16.h),

              // Quiz History
              _QuizHistoryStatic(),
              SizedBox(height: 16.h),

              // Quiz Progress
              _QuizProgressCardStatic(quizPercent01: 0.65),
              SizedBox(height: 16.h),

              // Overall Progress Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
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
                        child: Icon(
                          Icons.auto_graph_rounded,
                          size: 24.sp,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tổng tiến độ',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${overallProgress.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 20.sp,
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
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Subjects Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Môn học ($currentGrade)',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${displaySubjects.length} môn',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Horizontal Scrollable Subjects
              Container(
                height: 240.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: displaySubjects.length,
                  itemBuilder: (context, index) {
                    final subject = displaySubjects[index];
                    return _buildSubjectCard(
                      subject['name'],
                      subject['code'],
                      subject['grade'],
                      subject['completedLessons'],
                      subject['totalLessons'],
                      subject['progressPercent'],
                      subject['hasProgress'],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// ========================= STREAK (API) =========================
class _StreakCardFromApi extends StatelessWidget {
  const _StreakCardFromApi();

  @override
  Widget build(BuildContext context) {
    final pc = Get.find<ProgressController>();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (!pc.streakLoaded.value) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final cur = pc.currentStreak.value;
          final best = pc.bestStreak.value;
          final total = pc.totalDays.value;
          final last = pc.lastActive.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.local_fire_department, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Chuỗi ngày học liên tiếp',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(value: '$cur', label: 'Ngày liên tiếp'),
                  _StatChip(value: '$total', label: 'Tổng ngày học'),
                  _StatChip(value: '$best', label: 'Kỷ lục'),
                ],
              ),
              if (last != null) ...[
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Hoạt động gần nhất: ${DateFormat('dd/MM/yyyy').format(last)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

/// ========================= QUIZ % (STATIC) =========================
class _QuizProgressCardStatic extends StatelessWidget {
  final double quizPercent01; // 0..1
  const _QuizProgressCardStatic({required this.quizPercent01});

  @override
  Widget build(BuildContext context) {
    final pct = (quizPercent01 * 100).clamp(0, 100).toStringAsFixed(0);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tiến độ Quiz',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: quizPercent01.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.blue.withOpacity(0.15),
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Đã hoàn thành $pct% số quiz',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// ========================= QUIZ HISTORY (STATIC BAR CHART) =========================
class _QuizHistoryStatic extends StatelessWidget {
  const _QuizHistoryStatic({super.key});

  // Tạo data cứng: 7 ngày gần nhất với tỉ lệ đúng ngẫu nhiên
  List<DateTime> _last7Days() {
    final today = DateTime.now();
    return List.generate(
        7,
            (i) => DateTime(today.year, today.month, today.day)
            .subtract(Duration(days: 6 - i)));
  }

  @override
  Widget build(BuildContext context) {
    final days = _last7Days();
    // dữ liệu % đúng (0..100) cứng để test
    final List<double> percents = [40, 55, 62, 80, 70, 50, 90];

    final avg = percents.isEmpty
        ? 0.0
        : percents.reduce((a, b) => a + b) / percents.length;

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
            Text(
              'Điểm trung bình: ${avg.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              DateFormat('dd/MM').format(days[idx]),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  barGroups: List.generate(days.length, (i) {
                    final p = percents[i].clamp(0.0, 100.0);
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: p,
                          width: 14,
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: Colors.blue.withOpacity(0.15),
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
  }
}