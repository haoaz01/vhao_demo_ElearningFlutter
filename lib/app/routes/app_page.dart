import 'package:get/get.dart';
import 'package:flutter_elearning_application/app/routes/app_routes.dart';
import 'package:flutter_elearning_application/screens/login_screen.dart';
import 'package:flutter_elearning_application/screens/signup_screen.dart';
import 'package:flutter_elearning_application/screens/welcome_screen.dart';

import '../../screens/forgot_password_screen.dart';
import '../../screens/lesson_detail_screen.dart';
import '../../screens/practice_exam_detail_screen.dart';
import '../../screens/practice_exam_screen.dart';
import '../../screens/quiz_detail_screen.dart';
import '../../screens/quiz_history_screen.dart';
import '../../screens/quiz_result_screen.dart';
import '../../screens/quiz_screen.dart';
import '../../screens/reset_pass_screen.dart';
import '../../screens/solve_exercises_detail.dart';
import '../../screens/subject_detail_screen.dart';
import '../../screens/theory_screen.dart';
import '../../widgets/main_widgets.dart';

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.welcome, page: () => WelcomeScreen()),
    GetPage(name: AppRoutes.signup, page: () => SignupScreen()),
    GetPage(name: AppRoutes.login, page: () => LoginScreen()),
    GetPage(name: AppRoutes.main, page: () => MainScreen()),
    GetPage(name: AppRoutes.forgotPassword, page: () => ForgotPasswordScreen()),
    GetPage(
      name: AppRoutes.resetPassword,
      page: () => ResetPasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.subjectDetail,
      page: () => SubjectDetailScreen(
        grade: Get.arguments['grade'],
        subject: Get.arguments['subject'],
      ),
      transition: Transition.rightToLeftWithFade,
    ),

    GetPage(
      name: AppRoutes.theory,
      page: () {
        final args = Get.arguments ?? {};
        return TheoryScreen(
          subject: args['subject'] ?? 'Toán',
          grade: args['grade'] ?? 6,
        );
      },
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.lessonDetail,
      page: () {
        final args = Get.arguments ?? {};
        final lesson = args['lesson'];
        return LessonDetailScreen(lesson: lesson);
      },
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.practiceExam,
      page: () {
        final args = Get.arguments ?? {};
        return PracticeExamScreen(
          subject: args['subject'],
          grade: args['grade'],
          practiceExamController: args['controller'],
        );
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.practiceExamDetail,
      page: () {
        final args = Get.arguments ?? {};
        return PracticeExamDetailScreen(
          fileName: args['fileName'],
        );
      },
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.solveExercisesDetail,
      page: () {
        final arguments = Get.arguments;
        final lessonId = arguments['lessonId'];
        return SolveExercisesDetailScreen(lessonId: lessonId);
      },
    ),

    GetPage(
      name: AppRoutes.quizDetail,
      page: () {
        final args = Get.arguments ?? {};
        return QuizDetailScreen(
          subject: args['subject'],
          grade: args['grade'],
        );
      },
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.quiz,
      page: () => const QuizScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.quizResult,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return QuizResultScreen(
          chapterName: args['chapterName'] ?? 'Unknown',
          setTitle: args['setTitle'] ?? 'Unknown',
          score: args['score'] ?? 0,
          correct: args['correct'] ?? 0,
          total: args['total'] ?? 0,
          quizTypeId: args['quizTypeId'] ?? 0,
          attemptNo: args['attemptNo'] ?? 1,
          durationSeconds: args['durationSeconds'] ?? 0,
          quizId: args['quizId'] ?? 0, // Add this line
        );
      },
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.quizHistory,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return QuizHistoryScreen(quizId: args['quizId']);
      },
      transition: Transition.cupertino,
    ),
  ];
}
