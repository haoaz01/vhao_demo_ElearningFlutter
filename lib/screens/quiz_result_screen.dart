import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
import '../controllers/quiz_controller.dart';
import '../screens/quiz_history_screen.dart';

class QuizResultScreen extends StatelessWidget {
  final String chapterName;
  final String setTitle;
  final double score;
  final int correct;
  final int total;
  final int quizTypeId;
  final int attemptNo;
  final int durationSeconds;
  final int quizId;

  QuizResultScreen({
    super.key,
    required this.chapterName,
    required this.setTitle,
    required this.score,
    required this.correct,
    required this.total,
    required this.quizTypeId,
    required this.attemptNo,
    required this.durationSeconds,
    required this.quizId,
  });

  final QuizController quizController = Get.find<QuizController>();

  String formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int sec = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Color getScoreColor() {
    if (score >= 8) return Colors.green.shade700;
    if (score >= 5) return Colors.orange;
    return Colors.red;
  }

  IconData getScoreIcon() {
    if (score >= 8) return Icons.emoji_events;
    if (score >= 5) return Icons.check_circle;
    return Icons.error;
  }

  String getScoreText() {
    if (score >= 8) return "Xuất sắc!";
    if (score >= 5) return "Hoàn thành!";
    return "Cần cố gắng!";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "Kết quả Quiz",
            style: TextStyle(color: Colors.white, fontSize: 16.sp)
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.green.shade100,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              // Score circle
              Container(
                width: 150.w,
                height: 150.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: getScoreColor(),
                    width: 4.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      getScoreIcon(),
                      size: 40.sp,
                      color: getScoreColor(),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: getScoreColor(),
                      ),
                    ),
                    Text(
                      "/10",
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                getScoreText(),
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: getScoreColor(),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Chương: $chapterName",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.green.shade800,
                ),
              ),
              Text(
                "Bộ đề: $setTitle",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.green.shade800,
                ),
              ),
              SizedBox(height: 32.h),
              // Results card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      _buildResultRow("Số câu đúng", "$correct/$total"),
                      Divider(height: 20.h),
                      _buildResultRow("Thời gian hoàn thành", formatDuration(durationSeconds)),
                      Divider(height: 20.h),
                      _buildResultRow("Lần thử", "$attemptNo"),
                      Divider(height: 20.h),
                      _buildResultRow(
                        "Loại đề",
                        quizTypeId == 1
                            ? "15 phút"
                            : quizTypeId == 2
                            ? "30 phút"
                            : "Không xác định",
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              // History Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.toNamed(AppRoutes.quizHistory, arguments: {'quizId': quizId});
                  },
                  icon: Icon(Icons.history, size: 20.sp),
                  label: Text(
                    "Xem Lịch Sử",
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Home Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton.icon(
                  onPressed: () => Get.offAllNamed(AppRoutes.main),
                  icon: Icon(Icons.home, size: 20.sp),
                  label: Text(
                    "Về Trang Chính",
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}