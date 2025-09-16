import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quiz_controller.dart';
import '../model/question_model.dart';
import 'quiz_result_screen.dart';
import '../widgets/inline_latex_text.dart'; // Import the Question model

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizController quizController = Get.find<QuizController>();

  late String chapterName;
  late String setTitle;
  late List<Question> questions;

  int currentQuestion = 0;
  Map<int, int> selectedAnswers = {};
  bool isSubmitted = false;

  late int remainingSeconds;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    chapterName = args['chapterName'];
    setTitle = args['setTitle'];
    questions = args['questions'];

    if (setTitle.toLowerCase().contains("15p")) {
      remainingSeconds = 15 * 60;
    } else if (setTitle.toLowerCase().contains("30p")) {
      remainingSeconds = 30 * 60;
    } else {
      remainingSeconds = 20 * 60;
    }

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
        setState(() {
          remainingSeconds--;
        });
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
    Map<int, int> userAnswersForBackend = {};

    for (int i = 0; i < questions.length; i++) {
      // Find the correct answer index for this question
      int correctAnswerIndex = -1;
      for (int j = 0; j < questions[i].choices.length; j++) {
        if (questions[i].choices[j].isCorrect) {
          correctAnswerIndex = j;
          break;
        }
      }

      // Convert index-based answers to ID-based answers for backend
      if (selectedAnswers.containsKey(i)) {
        int selectedIndex = selectedAnswers[i]!;
        userAnswersForBackend[questions[i].id] = questions[i].choices[selectedIndex].id;
      }

      if (selectedAnswers[i] == correctAnswerIndex) {
        correct++;
      }
    }

    int score = ((correct / questions.length) * 10).round();

    // Update local result
    quizController.updateResult(chapterName, setTitle, score, correct);

    setState(() {
      isSubmitted = true;
      timer?.cancel();
    });

    // Post result to backend
    try {
      await quizController.postQuizResult(
        chapterName: chapterName,
        setTitle: setTitle,
        score: score,
        correct: correct,
        total: questions.length,
        quizTypeId: setTitle.toLowerCase().contains("15p") ? 1 : 2,
        userAnswers: userAnswersForBackend,
      );
    } catch (e) {
      print("Error posting quiz result: $e");
      // Still show the result even if posting fails
    }

    Get.off(() => QuizResultScreen(
      chapterName: chapterName,
      setTitle: setTitle,
      score: score,
      correct: correct,
      total: questions.length,
      quizTypeId: setTitle.toLowerCase().contains("15p") ? 1 : 2,
    ));
  }


  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = questions[currentQuestion];

    // Find the correct answer index for the current question
    int correctAnswerIndex = -1;
    for (int i = 0; i < currentQ.choices.length; i++) {
      if (currentQ.choices[i].isCorrect) {
        correctAnswerIndex = i;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(setTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade600,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                formatTime(remainingSeconds),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: remainingSeconds <= 30 ? Colors.red : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Câu ${currentQuestion + 1}/${questions.length}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            InlineLatexText(text: currentQ.content, fontSize: 17, fontWeight: FontWeight.w500),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: currentQ.choices.length,
                itemBuilder: (context, index) {
                  final choice = currentQ.choices[index];
                  final selected = selectedAnswers[currentQuestion] == index;
                  final isCorrect = correctAnswerIndex == index;

                  Color borderColor = Colors.grey.shade400;
                  Color textColor = Colors.black;

                  if (isSubmitted) {
                    if (isCorrect) {
                      borderColor = Colors.green;
                      textColor = Colors.green;
                    } else if (selected) {
                      borderColor = Colors.red;
                      textColor = Colors.red;
                    }
                  } else if (selected) {
                    borderColor = Colors.blue.shade400;
                    textColor = Colors.blue.shade600;
                  }

                  return GestureDetector(
                    onTap: isSubmitted
                        ? null
                        : () => setState(() => selectedAnswers[currentQuestion] = index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSubmitted
                                ? (isCorrect ? Colors.green : selected ? Colors.red : Colors.grey)
                                : selected
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: InlineLatexText(text: choice.content, fontSize: 16, color: textColor)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentQuestion > 0 ? () => setState(() => currentQuestion--) : null,
                  child: const Text("Trước"),
                ),
                ElevatedButton(
                  onPressed: currentQuestion < questions.length - 1
                      ? () => setState(() => currentQuestion++)
                      : null,
                  child: const Text("Tiếp"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
                  backgroundColor: isSubmitted ? Colors.grey.shade400 : Colors.green.shade600,
                ),
                child: Text(isSubmitted ? "Đã nộp bài" : "Nộp bài",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}