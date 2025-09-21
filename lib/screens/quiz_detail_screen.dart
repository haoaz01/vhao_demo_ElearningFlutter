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

  final QuizController quizController = Get.find<QuizController>();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (quizController.chapters.isEmpty) {
        quizController.loadQuiz(subject, grade);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Quiz - $subject Lớp $grade",
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter["chapter"],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                          final quiz = quizSet["quiz"];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                quizSet["title"],
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text("Điểm: $score | Đúng: $correct/$totalQuestions"),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  await Get.toNamed(
                                    AppRoutes.quiz,
                                    arguments: {
                                      'chapterName': chapter["chapter"],
                                      'setTitle': quizSet["title"],
                                      'questions': quizSet["questions"],
                                      'quizId': quiz.id,
                                      'quizTypeId': quiz.quizTypeId,
                                    },
                                  );
                                  await quizController.loadQuiz(subject, grade);
                                  quizController.update();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCompleted ? Colors.blue : Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(isCompleted ? "Làm lại" : "Bắt đầu"),
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
