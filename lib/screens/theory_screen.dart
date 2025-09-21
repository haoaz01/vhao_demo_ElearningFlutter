import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
import '../controllers/theory_controller.dart';

class TheoryScreen extends StatelessWidget {
  final String subject;
  final int grade;
  final String mode; // Thêm biến mode để xác định flow
  final Color primaryGreen = const Color(0xFF4CAF50);

  TheoryScreen({Key? key, required this.subject, required this.grade})
      : mode = Get.arguments?['mode'] ?? 'theory', // Lấy mode từ arguments
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final TheoryController theoryController = Get.put(TheoryController());
    theoryController.loadTheory(subject, grade);

    return Scaffold(
      appBar: AppBar(
        title: Text(mode == 'theory'
            ? "Lý thuyết $subject - Khối $grade"
            : "Giải bài tập $subject - Khối $grade"),
        backgroundColor: primaryGreen,
      ),
      body: Obx(() {
        if (theoryController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: theoryController.chapters.length,
          itemBuilder: (context, index) {
            final chapter = theoryController.chapters[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: primaryGreen,
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                title: Text(
                  chapter.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                children: List.generate(chapter.lessons.length, (lessonIndex) {
                  final lesson = chapter.lessons[lessonIndex];
                  final isDone = theoryController.isCompleted(
                      theoryController.subject,
                      theoryController.grade,
                      lesson.title
                  );
                  return ListTile(
                    leading: Hero(
                      tag: lesson.title,
                      child: Icon(Icons.menu_book,
                          color: isDone ? primaryGreen : Colors.blue),
                    ),
                    title: Text(
                      lesson.title,
                      style: TextStyle(
                        color: isDone ? primaryGreen : Colors.black87,
                        fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      isDone ? Icons.check_circle : Icons.arrow_forward_ios,
                      color: isDone ? Colors.green : Colors.grey,
                    ),
                    onTap: () {
                      if (mode == 'theory') {
                        // Flow lý thuyết: đi đến trang chi tiết bài học
                        Get.toNamed(
                          AppRoutes.lessonDetail,
                          arguments: {'lesson': lesson},
                        );
                      } else {
                        // Flow giải bài tập: đi đến trang giải bài tập
                        Get.toNamed(
                          AppRoutes.solveExercisesDetail,
                          arguments: {'lessonId': lesson.id}, // Chỉ truyền ID
                        );
                      }
                    },
                  );
                }),
              ),
            );
          },
        );
      }),
    );
  }
}