// quiz_result_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
import '../controllers/quiz_controller.dart';

class QuizResultScreen extends StatelessWidget {
  final String chapterName;
  final String setTitle;
  final int score;
  final int correct;
  final int total;
  final int quizTypeId;

  QuizResultScreen({
    super.key,
    required this.chapterName,
    required this.setTitle,
    required this.score,
    required this.correct,
    required this.total,
    required this.quizTypeId,
  });

  final QuizController quizController = Get.find<QuizController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kết quả Quiz"),
        backgroundColor: Colors.green.shade600,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                score >= 5 ? Icons.emoji_events : Icons.error,
                color: score >= 5 ? Colors.orange : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                "Bạn đã hoàn thành Quiz!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text("Chương: $chapterName\nBộ đề: $setTitle",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Text(
                "Điểm: $score / 10",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: score >= 5 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text("Đúng: $correct / $total câu", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              Text("Loại đề: ${quizTypeId == 1 ? "15 phút" : "30 phút"}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Get.offAllNamed(AppRoutes.main),
                icon: const Icon(Icons.home),
                label: const Text("Về Trang Chính"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.green.shade600,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}