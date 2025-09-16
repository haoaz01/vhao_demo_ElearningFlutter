import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
import '../controllers/quiz_controller.dart';

class QuizDetailScreen extends StatelessWidget {
  final String subject;
  final int grade;

  QuizDetailScreen({
    super.key,
    required this.subject,
    required this.grade,
  });

  final QuizController quizController = Get.put(QuizController());

  @override
  Widget build(BuildContext context) {
    // Load quiz khi screen được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (quizController.chapters.isEmpty) {
        quizController.loadQuiz(subject, grade);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Danh sách Quiz",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade600,
      ),
      body: Obx(() {
        if (quizController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (quizController.chapters.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Không có quiz nào"),
                ElevatedButton(
                  onPressed: () => quizController.loadQuiz(subject, grade),
                  child: const Text("Thử lại"),
                )
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => await quizController.loadQuiz(subject, grade),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quizController.chapters.length,
            itemBuilder: (context, chapterIndex) {
              final chapter = quizController.chapters[chapterIndex];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter["chapter"],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: chapter["sets"].length,
                        itemBuilder: (context, setIndex) {
                          final quizSet = chapter["sets"][setIndex];
                          final score = quizController.getScore(chapter["chapter"], quizSet["title"]);
                          final correct = quizController.getCorrectAnswers(chapter["chapter"], quizSet["title"]);
                          final totalQuestions = quizSet["questions"].length;
                          final isCompleted = quizController.isCompleted(chapter["chapter"], quizSet["title"]);

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quizSet["title"],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Điểm: $score"),
                                      Text("Đúng: $correct / $totalQuestions"),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isCompleted
                                            ? Colors.blue.shade600
                                            : Colors.green.shade600,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () async {
                                        await Get.toNamed(
                                          AppRoutes.quiz,
                                          arguments: {
                                            'chapterName': chapter["chapter"],
                                            'setTitle': quizSet["title"],
                                            'questions': quizSet["questions"],
                                            'isReview': isCompleted,
                                          },
                                        );
                                        await quizController.loadQuiz(subject, grade);
                                        quizController.update();
                                      },
                                      child: Text(
                                        isCompleted ? "Xem lại" : "Bắt đầu",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}