import 'package:flutter/material.dart';
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
        title: Text("Bộ đề thi ${widget.subject} lớp ${widget.grade}"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          if (widget.practiceExamController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.practiceExamController.errorMessage.isNotEmpty) {
            return Center(
              child: Text(
                widget.practiceExamController.errorMessage.value,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (widget.practiceExamController.exams.isEmpty) {
            return const Center(
              child: Text("Chưa có đề thi nào cho môn học này"),
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
        title: Text(
          exam.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Loại: ${_getExamTypeName(exam.examType)} - Ngày tải: ${_formatDate(exam.uploadDate)}",
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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