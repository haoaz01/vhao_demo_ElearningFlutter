import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          width: 42.w,
          height: 42.h,
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
          width: 42.w,
          height: 42.h,
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
          width: 42.w,
          height: 42.h,
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
          width: 42.w,
          height: 42.h,
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
        title: Text(
          "Khối $grade - $subject",
          style: TextStyle(fontSize: 18.sp),
        ),
        backgroundColor: primaryGreen,
        elevation: 2,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$subject cho Khối $grade",
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "Chọn nội dung bạn muốn học bên dưới:",
              style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black54
              ),
            ),
            SizedBox(height: 24.h),

            Expanded(
              child: GridView.builder(
                itemCount: featureCards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final card = featureCards[index];
                  return InkWell(
                    onTap: card["onTap"],
                    borderRadius: BorderRadius.circular(18.r),
                    splashColor: card["color"].withOpacity(0.2),
                    highlightColor: Colors.white.withOpacity(0.1),
                    child: Card(
                      elevation: 6,
                      shadowColor: card["color"].withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12.w), // Giảm padding
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon Section
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: card["color"].withOpacity(0.15),
                              ),
                              padding: EdgeInsets.all(10.w), // Giảm padding
                              child: card["icon"],
                            ),
                            SizedBox(height: 8.h), // Giảm khoảng cách

                            // Title
                            Text(
                              card["title"],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.sp, // Giảm font size
                                fontWeight: FontWeight.bold,
                                color: (card["color"] as MaterialColor).shade700,
                              ),
                            ),

                            // Progress Bar (chỉ cho Lý thuyết)
                            if (card["title"] == "Lý thuyết") ...[
                              SizedBox(height: 8.h), // Giảm khoảng cách
                              Obx(() {
                                double progress =
                                theoryController.getProgress(subject, grade);
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6.h, // Giảm chiều cao
                                      backgroundColor:
                                      card["color"].withOpacity(0.2),
                                      color: card["color"],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      "${(progress * 100).toStringAsFixed(0)}%",
                                      style: TextStyle(
                                        fontSize: 10.sp, // Giảm font size
                                      ),
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