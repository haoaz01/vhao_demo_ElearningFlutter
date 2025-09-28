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
    await progressController.loadQuizStats(days: 7); // <-- gọi thêm
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
              _QuizHistoryFromApi(),
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


class _QuizHistoryFromApi extends StatelessWidget {
  const _QuizHistoryFromApi({super.key});

  @override
  Widget build(BuildContext context) {
    final pc = Get.find<ProgressController>();

    return Obx(() {
      if (pc.isQuizLoading.value) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      final data = pc.quizDaily;
      if (data.isEmpty) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Chưa có dữ liệu quiz trong thời gian gần đây'),
          ),
        );
      }

      final days = data.map((e) => e.day).toList();
      final percents = data.map((e) => e.percent.clamp(0.0, 100.0)).toList();
      final avg = percents.isEmpty ? 0.0 : percents.reduce((a, b) => a + b) / percents.length;

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
                height: 260, // khung cao hơn chút cho thoáng
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: 120, // nới trần để 100% không chạm đỉnh
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),

                    // Đường tham chiếu 100% để "đều hàng"
                    extraLinesData: ExtraLinesData(horizontalLines: [
                      HorizontalLine(
                        y: 100,
                        dashArray: [6, 4],
                        strokeWidth: 1,
                        color: Colors.grey.withOpacity(0.6),
                      ),
                    ]),

                    // Tooltip khi chạm vào cột
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBorderRadius: BorderRadius.circular(6),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final pct = (rod.toY / 1).clamp(0, 120); // giá trị hiển thị
                          return BarTooltipItem(
                            '${pct.toStringAsFixed(0)}%',
                            const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        },
                      ),
                    ),

                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          interval: 20, // 0,20,40,60,80,100
                          getTitlesWidget: (value, _) {
                            // Ẩn nhãn > 100 để không gây rối khi maxY = 120
                            if (value > 100) return const SizedBox.shrink();
                            return Text('${value.toInt()}%');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
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
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),

                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      // Chỉ kẻ tới 100 để đỡ rối phần trên
                      checkToShowHorizontalLine: (value) => value % 20 == 0 && value <= 100,
                    ),

                    barGroups: List.generate(days.length, (i) {
                      final p = percents[i];              // % thật (0..100)
                      const scale = 0.92;                 // 💡 thu nhỏ nhẹ chiều cao cột ~8%
                      final toY = (p * scale).clamp(0.0, 119.0); // không vượt trần

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
                            backDrawRodData: BackgroundBarChartRodData(show: false),
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