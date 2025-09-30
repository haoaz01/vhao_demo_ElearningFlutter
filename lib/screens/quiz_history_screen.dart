// QuizHistoryScreen
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/quiz_history_controller.dart';
import '../controllers/quiz_controller.dart';
import '../model/question_content_model.dart';
import '../widgets/inline_latex_text.dart';

class QuizHistoryScreen extends StatefulWidget {
  final int quizId;

  const QuizHistoryScreen({required this.quizId, Key? key}) : super(key: key);

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen>
    with SingleTickerProviderStateMixin {
  final QuizHistoryController quizController = Get.find<QuizHistoryController>();
  final QuizController questionController = Get.find<QuizController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    quizController.fetchQuizHistory(widget.quizId); // ✅ chỉ gọi controller này
    questionController.fetchQuizQuestions(widget.quizId);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildContent(List<QuestionContent> contents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contents.map((content) {
        if (content.contentType == "TEXT") {
          return InlineLatexText(
            text: content.contentValue,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          );
        } else if (content.contentType == "IMAGE") {
          return Container(
            margin: EdgeInsets.only(top: 8.h),
            child: Image.network(
              content.contentValue,
              fit: BoxFit.contain,
              width: double.infinity,
              height: 120.h,
            ),
          );
        } else {
          return const SizedBox();
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Lịch sử Quiz",
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
          tabs: [
            Tab(text: "Lịch sử làm bài"),
            Tab(text: "Giải thích"),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildHistoryTab(),
            _buildExplanationTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Obx(() {
      if (quizController.isLoadingHistory.value) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        );
      }

      if (quizController.history.isEmpty) { // 👈
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64.w, color: Colors.green.shade300),
              SizedBox(height: 16.h),
              Text("Chưa có lịch sử làm bài", style: TextStyle(fontSize: 18.sp)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: quizController.history.length,
        itemBuilder: (context, index) {
          final attempt = quizController.history[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 3,
            margin: EdgeInsets.only(bottom: 16.h),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Lần thứ ${attempt.attemptNo}",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getScoreColor(attempt.score),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          "${attempt.score.toStringAsFixed(1)}/10",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(attempt.completedAt)}",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "Thời gian: ${_formatDuration(attempt.durationSeconds)}",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "Số câu đúng: ${attempt.correctAnswers}/${attempt.totalQuestions}",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildExplanationTab() {
    return Obx(() {
      if (questionController.questions.isEmpty) { // 👈
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book, size: 64.w, color: Colors.green.shade300),
              SizedBox(height: 16.h),
              Text("Chưa có dữ liệu giải thích", style: TextStyle(fontSize: 18.sp)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: questionController.questions.length, // 👈
        itemBuilder: (context, index) {
          final question = questionController.questions[index]; // 👈
          final correctChoice = question.choices.firstWhere((c) => c.isCorrect);
          return Card(
            margin: EdgeInsets.only(bottom: 20.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Câu ${index + 1}",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildContent(question.contents),
                  SizedBox(height: 12.h),
                  Text(
                    "Đáp án đúng:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: InlineLatexText(
                      text: correctChoice.content,
                      fontSize: 15.sp,
                    ),
                  ),
                  if (question.explanation.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Text(
                      "Giải thích:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: InlineLatexText(
                        text: question.explanation,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green.shade700;
    if (score >= 5) return Colors.orange;
    return Colors.red;
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int sec = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}