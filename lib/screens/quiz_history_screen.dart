import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/quiz_controller.dart';
import '../widgets/inline_latex_text.dart';

class QuizHistoryScreen extends StatefulWidget {
  final int quizId;

  const QuizHistoryScreen({required this.quizId, Key? key}) : super(key: key);

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen>
    with SingleTickerProviderStateMixin {
  final QuizController quizController = Get.find<QuizController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    quizController.fetchQuizHistory(widget.quizId);
    quizController.fetchQuizQuestions(widget.quizId);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử Quiz", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
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

  /// Tab 1: Lịch sử làm bài
  Widget _buildHistoryTab() {
    return Obx(() {
      if (quizController.isHistoryLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        );
      }

      if (quizController.quizHistory.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.green.shade300),
              const SizedBox(height: 16),
              const Text("Chưa có lịch sử làm bài", style: TextStyle(fontSize: 18)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quizController.quizHistory.length,
        itemBuilder: (context, index) {
          final attempt = quizController.quizHistory[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Lần thứ ${attempt.attemptNo}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getScoreColor(attempt.score),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${attempt.score.toStringAsFixed(1)}/10",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(attempt.completedAt)}",
                      style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Text("Thời gian: ${_formatDuration(attempt.durationSeconds)}",
                      style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Text("Số câu đúng: ${attempt.correctAnswers}/${attempt.totalQuestions}",
                      style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  /// Tab 2: Giải thích từng câu hỏi
  Widget _buildExplanationTab() {
    return Obx(() {
      if (quizController.questions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book, size: 64, color: Colors.green.shade300),
              const SizedBox(height: 16),
              const Text("Chưa có dữ liệu giải thích", style: TextStyle(fontSize: 18)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quizController.questions.length,
        itemBuilder: (context, index) {
          final question = quizController.questions[index];
          final correctChoice = question.choices.firstWhere((c) => c.isCorrect);

          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Câu ${index + 1}",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                  const SizedBox(height: 8),
                  InlineLatexText(text: question.content, fontSize: 16, fontWeight: FontWeight.w500),
                  const SizedBox(height: 12),
                  const Text("Đáp án đúng:",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InlineLatexText(text: correctChoice.content, fontSize: 15),
                  ),
                  if (question.explanation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text("Giải thích:",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InlineLatexText(text: question.explanation, fontSize: 14),
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
