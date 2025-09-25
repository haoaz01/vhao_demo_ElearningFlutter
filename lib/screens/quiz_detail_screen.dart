import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:device_preview/device_preview.dart';

import '../app/routes/app_routes.dart';
import '../controllers/quiz_controller.dart';
import '../controllers/auth_controller.dart';

class QuizDetailScreen extends StatelessWidget {
  final String subject;
  final int grade;

  QuizDetailScreen({
    super.key,
    required this.subject,
    required this.grade,
  });

  final QuizController quizController = Get.find<QuizController>();
  final AuthController authController = Get.find<AuthController>();

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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        backgroundColor: Colors.green.shade600,
      ),
      body: Obx(() {
        if (quizController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(strokeWidth: 2.w),
          );
        }

        if (quizController.chapters.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Không có quiz nào",
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => quizController.loadQuiz(subject, grade),
                  child: Text(
                    "Thử lại",
                    style: TextStyle(fontSize: 14.sp),
                  ),
                )
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => await quizController.loadQuiz(subject, grade),
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: quizController.chapters.length,
            itemBuilder: (context, chapterIndex) {
              final chapter = quizController.chapters[chapterIndex];

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r)),
                elevation: 5,
                margin: EdgeInsets.only(bottom: 20.h),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter["chapter"],
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: chapter["sets"].length,
                        itemBuilder: (context, setIndex) {
                          final quizSet = chapter["sets"][setIndex];
                          final score = quizController.getScore(
                              chapter["chapter"], quizSet["title"]);
                          final correct = quizController.getCorrectAnswers(
                              chapter["chapter"], quizSet["title"]);
                          final totalQuestions = quizSet["questions"].length;
                          final isCompleted = quizController.isCompleted(
                              chapter["chapter"], quizSet["title"]);
                          final quiz = quizSet["quiz"];

                          // 🔹 LẤY BEST SCORE
                          final hasBestScore =
                          quizController.hasBestScoreForQuiz(quiz.id);
                          final bestScore =
                          quizController.getBestScoreForQuiz(quiz.id);
                          final bestCorrect =
                          quizController.getBestCorrectForQuiz(quiz.id);
                          final isPassedBest =
                          quizController.isQuizPassedBest(quiz.id);

                          return Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              title: Text(
                                quizSet["title"],
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isCompleted)
                                    Text(
                                      "Lần gần nhất: $score/10 điểm - $correct/$totalQuestions câu đúng",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  if (hasBestScore)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Image.asset("assets/icon/icon_medal.png",
                                          width: 30.w,
                                          height: 30.h,),
                                        SizedBox(width: 4.w),
                                        Expanded(
                                          child: Text(
                                            "${bestScore.toStringAsFixed(1)}/10 điểm\n"
                                                "$bestCorrect/$totalQuestions câu đúng",
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                              color: isPassedBest ? Colors.deepOrange : Colors.grey,
                                              height: 1.4, // tạo khoảng cách dòng đẹp hơn
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (!isCompleted && !hasBestScore)
                                    Text(
                                      "Chưa hoàn thành",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (authController.userId.value > 0) {
                                        await quizController
                                            .loadBestScoreForQuiz(quiz.id);
                                      }

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
                                      await quizController.loadQuiz(
                                          subject, grade);
                                      quizController.update();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(10.r),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 8.h,
                                      ),
                                    ),
                                    child: Text(
                                      "Bắt đầu",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.white,
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