import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/quiz_controller.dart';
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
          durationSeconds
      );

      Get.off(() => QuizResultScreen(
        chapterName: chapterName,
        setTitle: setTitle,
        score: result.score,
        correct: result.correctAnswers,
        total: result.totalQuestions,
        quizTypeId: quizTypeId,
        attemptNo: result.attemptNo,
        durationSeconds: result.durationSeconds,
        quizId: quizId,
      ));
    } catch (e) {
      Get.off(() => QuizResultScreen(
        chapterName: chapterName,
        setTitle: setTitle,
        score: score.toDouble(),
        correct: correct,
        total: questions.length,
        quizTypeId: quizTypeId,
        attemptNo: 1,
        durationSeconds: durationSeconds,
        quizId: quizId,
      ));
    }
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
            Text(setTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(chapterName, style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: remainingSeconds <= 30 ? Colors.red : Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              formatTime(remainingSeconds),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (currentQuestion + 1) / questions.length,
              backgroundColor: Colors.grey.shade300,
              color: Colors.green,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 20),
            Text("Câu ${currentQuestion + 1}/${questions.length}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: InlineLatexText(
                  text: currentQ.content,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: currentQ.choices.length,
                itemBuilder: (context, index) {
                  final choice = currentQ.choices[index];
                  final selected = selectedAnswers[currentQuestion] == index;

                  return GestureDetector(
                    onTap: isSubmitted
                        ? null
                        : () => setState(() => selectedAnswers[currentQuestion] = index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected ? Colors.lightBlue.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? Colors.blue : Colors.grey.shade300,
                          width: 2,
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: InlineLatexText(text: choice.content, fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: currentQuestion > 0
                        ? () => setState(() => currentQuestion--)
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Trước"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: currentQuestion < questions.length - 1
                        ? () => setState(() => currentQuestion++)
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text("Tiếp"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isSubmitted ? "Đã nộp bài" : "Nộp bài",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
