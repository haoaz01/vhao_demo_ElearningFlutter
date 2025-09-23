import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
import '../controllers/practice_exam_controller.dart';
import '../controllers/theory_controller.dart';
import '../controllers/quiz_controller.dart';

class SubjectDetailScreen extends StatelessWidget {
  final Color primaryGreen = const Color(0xFF4CAF50);
  final int grade;
  final String subject;
  final TheoryController theoryController = Get.put(TheoryController());
  final QuizController quizController = Get.put(QuizController());

  SubjectDetailScreen({
    super.key,
    int? grade,
    String? subject,
  })  : grade = grade ?? (Get.arguments?['grade'] ?? 6),
        subject = subject ?? (Get.arguments?['subject'] ?? 'Toán');

  @override
  Widget build(BuildContext context) {
    // Load dữ liệu lý thuyết cho môn + khối
    theoryController.loadTheory(subject, grade);

    final List<Map<String, dynamic>> featureCards = [
      {
        "title": "Lý thuyết",
        "icon": Image.asset(
          "assets/icon/icon_theory.png",
          width: 42,
          height: 42,
          // Đã xóa color: để giữ nguyên màu PNG gốc
        ),
        "color": Colors.blue,
        "onTap": () {
          Get.toNamed(
            AppRoutes.theory,
            arguments: {
              'subject': subject,
              'grade': grade,
              'mode': 'theory',
            },
          );
        }
      },
      {
        "title": "Giải bài tập",
        "icon": Image.asset(
          "assets/icon/icon_solve_exercise.png",
          width: 42,
          height: 42,
          // Đã xóa color: để giữ nguyên màu PNG gốc
        ),
        "color": Colors.green,
        "onTap": () {
          Get.toNamed(
            AppRoutes.theory,
            arguments: {
              'subject': subject,
              'grade': grade,
              'mode': 'exercise',
            },
          );
        }
      },
      {
        "title": "Quiz",
        "icon": Image.asset(
          "assets/icon/icon_quiz.png",
          width: 42,
          height: 42,
          // Đã xóa color: để giữ nguyên màu PNG gốc
        ),
        "color": Colors.orange,
        "onTap": () async {
          try {
            await quizController.loadQuiz(subject, grade);

            if (quizController.chapters.isEmpty) {
              Get.snackbar("Thông báo", "Không có quiz nào cho môn học này");
              return;
            }

            Get.toNamed(
              AppRoutes.quizDetail,
              arguments: {
                'subject': subject,
                'grade': grade,
              },
            );
          } catch (e) {
            Get.snackbar("Lỗi", "Không thể tải quiz: $e");
          }
        }
      },
      {
        "title": "Bộ đề thi",
        "icon": Image.asset(
          "assets/icon/icon_exam.png",
          width: 42,
          height: 42,
          // Đã xóa color: để giữ nguyên màu PNG gốc
        ),
        "color": Colors.purple,
        "onTap": () {
          final tag = '${subject}_$grade';
          Get.create<PracticeExamController>(() => PracticeExamController(),
              tag: tag);
          Get.find<PracticeExamController>(tag: tag);

          Get.toNamed(
            AppRoutes.practiceExam,
            arguments: {
              'subject': subject,
              'grade': grade,
            },
          );
        }
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Khối $grade - $subject"),
        backgroundColor: primaryGreen,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$subject cho Khối $grade",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Chọn nội dung bạn muốn học bên dưới:",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Grid hiển thị các thẻ chức năng
            Expanded(
              child: GridView.builder(
                itemCount: featureCards.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final card = featureCards[index];
                  return InkWell(
                    onTap: card["onTap"],
                    borderRadius: BorderRadius.circular(18),
                    splashColor: card["color"].withOpacity(0.2),
                    highlightColor: Colors.white.withOpacity(0.1),
                    child: Card(
                      elevation: 6,
                      shadowColor: card["color"].withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: card["color"].withOpacity(0.15),
                                boxShadow: [
                                  BoxShadow(
                                    color: card["color"].withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: card["icon"], // Icon giữ nguyên màu gốc
                            ),
                            const SizedBox(height: 16),
                            Text(
                              card["title"],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: (card["color"] as MaterialColor).shade700,
                              ),
                            ),

                            // ✅ Thanh tiến trình chỉ cho "Lý thuyết"
                            if (card["title"] == "Lý thuyết") ...[
                              const SizedBox(height: 12),
                              Obx(() {
                                double progress =
                                theoryController.getProgress(subject, grade);
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor:
                                      card["color"].withOpacity(0.2),
                                      color: card["color"],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${(progress * 100).toStringAsFixed(0)}% Hoàn thành",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}