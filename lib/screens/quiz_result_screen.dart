import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
import '../controllers/quiz_controller.dart';

class QuizResultScreen extends StatelessWidget {
  final String chapterName;
  final String setTitle;
  final double score;
  final int correct;
  final int total;
  final int quizTypeId;
  final int attemptNo;
  final int durationSeconds;

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
        title: const Text("Kết quả Quiz", style: TextStyle(color: Colors.white)),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Score circle
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: getScoreColor(),
                    width: 4,
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
                      size: 40,
                      color: getScoreColor(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: getScoreColor(),
                      ),
                    ),
                    Text(
                      "/10",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                getScoreText(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: getScoreColor(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Chương: $chapterName",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green.shade800,
                ),
              ),
              Text(
                "Bộ đề: $setTitle",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 32),
              // Results card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildResultRow("Số câu đúng", "$correct/$total"),
                      const Divider(),
                      _buildResultRow("Thời gian hoàn thành", formatDuration(durationSeconds)),
                      const Divider(),
                      _buildResultRow("Lần thử", "$attemptNo"),
                      const Divider(),
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Get.offAllNamed(AppRoutes.main),
                  icon: const Icon(Icons.home),
                  label: const Text(
                    "Về Trang Chính",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}