import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/practice_exam_controller.dart';
import '../model/practice_exam_model.dart';
import 'practice_exam_detail_screen.dart';

class PracticeExamScreen extends StatefulWidget {
  final String subject;
  final String grade;
  final PracticeExamController practiceExamController;
  const PracticeExamScreen({
    Key? key,
    required this.subject,
    required this.grade,
    required this.practiceExamController,
  }) : super(key: key);

  @override
  State<PracticeExamScreen> createState() => _PracticeExamScreenState();
}

class _PracticeExamScreenState extends State<PracticeExamScreen> {
  final Color primaryGreen = const Color(0xFF4CAF50);
  @override
  void initState() {
    super.initState();
    // Load exams when the screen initializes
    widget.practiceExamController.loadExams(widget.subject, widget.grade);
  }

  @override
  void dispose() {
    // Clean up the controller when the screen is disposed
    Get.delete<PracticeExamController>(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Bộ đề thi ${widget.subject} lớp ${widget.grade}",
          style: TextStyle(fontSize: 16.sp),
        ),
        backgroundColor: primaryGreen,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Obx(() {
          if (widget.practiceExamController.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(strokeWidth: 2.w),
            );
          }

          if (widget.practiceExamController.errorMessage.isNotEmpty) {
            return Center(
              child: Text(
                widget.practiceExamController.errorMessage.value,
                style: TextStyle(color: Colors.red, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (widget.practiceExamController.exams.isEmpty) {
            return Center(
              child: Text(
                "Chưa có đề thi nào cho môn học này",
                style: TextStyle(fontSize: 16.sp),
              ),
            );
          }

          return ListView.builder(
            itemCount: widget.practiceExamController.exams.length,
            itemBuilder: (context, index) {
              final PracticeExam exam = widget.practiceExamController.exams[index];
              return _buildExamItem(exam, context);
            },
          );
        }),
      ),
    );
  }

  Widget _buildExamItem(PracticeExam exam, BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        leading: Icon(Icons.picture_as_pdf, color: Colors.red, size: 32.sp),
        title: Text(
          exam.description,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        subtitle: Text(
          "Loại: ${_getExamTypeName(exam.examType)} - Ngày tải: ${_formatDate(exam.uploadDate)}",
          style: TextStyle(fontSize: 12.sp),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
        onTap: () {
          Get.to(
                () => PracticeExamDetailScreen(fileName: exam.fileName),
            transition: Transition.rightToLeft,
          );
        },
      ),
    );
  }

  String _getExamTypeName(String examType) {
    switch (examType) {
      case 'giuaky': return 'Giữa kỳ';
      case 'cuoiky': return 'Cuối kỳ';
      default: return examType;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}