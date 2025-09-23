import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../controllers/quiz_controller.dart';
import '../model/question_content_model.dart';
import '../model/question_model.dart';
import 'quiz_result_screen.dart';
import '../widgets/inline_latex_text.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizController quizController = Get.find<QuizController>();
  final AuthController authController = Get.find<AuthController>();

  late String chapterName;
  late String setTitle;
  late List<Question> questions;
  late int quizId;
  late int quizTypeId;

  int currentQuestion = 0;
  Map<int, int> selectedAnswers = {};
  bool isSubmitted = false;

  late int remainingSeconds;
  late int totalSeconds;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    chapterName = args['chapterName'];
    setTitle = args['setTitle'];
    questions = args['questions'];
    quizId = args['quizId'];
    quizTypeId = args['quizTypeId'];

    if (quizTypeId == 1) {
      totalSeconds = 15 * 60;
    } else if (quizTypeId == 2) {
      totalSeconds = 30 * 60;
    } else {
      totalSeconds = 20 * 60;
    }

    remainingSeconds = totalSeconds;
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds <= 0) {
        timer.cancel();
        if (!isSubmitted) {
          _submitQuiz(autoSubmit: true);
        }
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int sec = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _submitQuiz({bool autoSubmit = false}) async {
    int correct = 0;
    Map<int, List<int>> userAnswersForBackend = {};

    for (int i = 0; i < questions.length; i++) {
      int correctAnswerIndex = -1;
      for (int j = 0; j < questions[i].choices.length; j++) {
        if (questions[i].choices[j].isCorrect) {
          correctAnswerIndex = j;
          break;
        }
      }

      if (selectedAnswers.containsKey(i)) {
        int selectedIndex = selectedAnswers[i]!;
        userAnswersForBackend[questions[i].id] = [questions[i].choices[selectedIndex].id];
      }

      if (selectedAnswers[i] == correctAnswerIndex) {
        correct++;
      }
    }

    int score = ((correct / questions.length) * 10).round();
    int durationSeconds = totalSeconds - remainingSeconds;

    quizController.updateResult(chapterName, setTitle, score, correct);

    setState(() {
      isSubmitted = true;
      timer?.cancel();
    });

    try {
      final result = await quizController.submitQuiz(
        quizId,
        userAnswersForBackend,
        durationSeconds,
      );

      Get.offNamed(
        AppRoutes.quizResult,
        arguments: {
          'chapterName': chapterName,
          'setTitle': setTitle,
          'score': result.score,
          'correct': result.correctAnswers,
          'total': result.totalQuestions,
          'quizTypeId': quizTypeId,
          'attemptNo': result.attemptNo,
          'durationSeconds': result.durationSeconds,
          'quizId': quizId,
        },
      );
    } catch (e) {
      Get.offNamed(
        AppRoutes.quizResult,
        arguments: {
          'chapterName': chapterName,
          'setTitle': setTitle,
          'score': score.toDouble(),
          'correct': correct,
          'total': questions.length,
          'quizTypeId': quizTypeId,
          'attemptNo': 1,
          'durationSeconds': durationSeconds,
          'quizId': quizId,
        },
      );
    }
  }

  // Widget để hiển thị danh sách nội dung (TEXT và IMAGE)
  Widget _buildContent(List<QuestionContent> contents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contents.map((content) {
        if (content.contentType == "TEXT") {
          return InlineLatexText(
            text: content.contentValue,
            fontSize: 17.sp,
            fontWeight: FontWeight.w500,
          );
        } else if (content.contentType == "IMAGE") {
          return Container(
            margin: EdgeInsets.only(top: 8.h),
            child: Image.network(
              content.contentValue,
              fit: BoxFit.contain,
              width: double.infinity,
              height: 150.h,
            ),
          );
        } else {
          return const SizedBox();
        }
      }).toList(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = questions[currentQuestion];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              setTitle,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
            Text(
              chapterName,
              style: TextStyle(fontSize: 12.sp),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: remainingSeconds <= 30 ? Colors.red : Colors.black54,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              formatTime(remainingSeconds),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: (currentQuestion + 1) / questions.length,
              backgroundColor: Colors.grey.shade300,
              color: Colors.green,
              minHeight: 10.h,
              borderRadius: BorderRadius.circular(10.r),
            ),
            SizedBox(height: 20.h),

            // Question Counter
            Text(
              "Câu ${currentQuestion + 1}/${questions.length}",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),

            // Question Card với Expanded để có thể scroll
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Question Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: _buildContent(currentQ.contents),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Choices List
                    ListView.builder(
                      shrinkWrap: true, // Quan trọng: cho phép ListView nằm trong ScrollView
                      physics: const NeverScrollableScrollPhysics(), // Vô hiệu hóa scroll riêng
                      itemCount: currentQ.choices.length,
                      itemBuilder: (context, index) {
                        final choice = currentQ.choices[index];
                        final selected = selectedAnswers[currentQuestion] == index;

                        return GestureDetector(
                          onTap: isSubmitted
                              ? null
                              : () => setState(() => selectedAnswers[currentQuestion] = index),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: selected ? Colors.lightBlue.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: selected ? Colors.blue : Colors.grey.shade300,
                                width: 2.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected ? Icons.check_circle : Icons.circle_outlined,
                                  color: selected ? Colors.blue : Colors.grey,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: InlineLatexText(
                                    text: choice.content,
                                    fontSize: 16.sp,
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
            ),
            SizedBox(height: 10.h),

            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: currentQuestion > 0
                        ? () => setState(() => currentQuestion--)
                        : null,
                    icon: Icon(Icons.arrow_back, size: 18.sp),
                    label: Text(
                      "Trước",
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: currentQuestion < questions.length - 1
                        ? () => setState(() => currentQuestion++)
                        : null,
                    icon: Icon(Icons.arrow_forward, size: 18.sp),
                    label: Text(
                      "Tiếp",
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Submit Button
            ElevatedButton(
              onPressed: isSubmitted
                  ? null
                  : () {
                if (selectedAnswers.length < questions.length) {
                  Get.snackbar(
                    "Thông báo",
                    "Vui lòng trả lời tất cả các câu hỏi!",
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                  );
                  return;
                }
                _submitQuiz();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSubmitted ? Colors.grey : Colors.green.shade600,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                minimumSize: Size(double.infinity, 50.h),
              ),
              child: Text(
                isSubmitted ? "Đã nộp bài" : "Nộp bài",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}