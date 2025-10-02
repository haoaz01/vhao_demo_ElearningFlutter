import 'package:get/get.dart';
import 'package:flutter_elearning_application/app/routes/app_routes.dart';
import 'package:flutter_elearning_application/screens/login_screen.dart';
import 'package:flutter_elearning_application/screens/signup_screen.dart';
import 'package:flutter_elearning_application/screens/welcome_screen.dart';

import '../../controllers/practice_exam_controller.dart';
import '../../middlewares/role_middleware.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/forgot_password_screen.dart';
import '../../screens/lesson_detail_screen.dart';
import '../../screens/practice_exam_detail_screen.dart';
import '../../screens/practice_exam_screen.dart';
import '../../screens/quiz_detail_screen.dart';
import '../../screens/quiz_history_screen.dart';
import '../../screens/quiz_result_screen.dart';
import '../../screens/quiz_screen.dart';
import '../../screens/reset_password_screen.dart';
import '../../screens/search_screen.dart';
import '../../screens/solve_exercises_detail.dart';
import '../../screens/subject_detail_screen.dart';
import '../../screens/theory_screen.dart';
import '../../widgets/main_widgets.dart';
import '../../widgets/root_shell.dart';

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.welcome, page: () => WelcomeScreen()),
    GetPage(name: AppRoutes.signup, page: () => SignupScreen()),
    GetPage(name: AppRoutes.login, page: () => LoginScreen()),
    GetPage(
      name: AppRoutes.main,
      page: () => MainScreen(),
      middlewares: [RoleMiddleware('USER')], // 👈 Bảo vệ route chính cho USER
    ),
    GetPage(name: AppRoutes.forgotPassword, page: () => ForgotPasswordScreen()),
    GetPage(name: AppRoutes.resetPassword, page: () => ResetPasswordScreen()),

    GetPage(
      name: AppRoutes.subjectDetail,
      page: () => SubjectDetailScreen(
        grade: Get.arguments['grade'],
        subject: Get.arguments['subject'],
      ),
      middlewares: [RoleMiddleware('USER')],
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
      middlewares: [RoleMiddleware('USER')],
    ),
    GetPage(
      name: AppRoutes.lessonDetail,
      page: () {
        final args = Get.arguments ?? {};
        final lesson = args['lesson'];
        return LessonDetailScreen(lesson: lesson);
      },
      middlewares: [RoleMiddleware('USER')],
    ),
    GetPage(
      name: AppRoutes.practiceExam,
      page: () {
        final args = Get.arguments ?? {};
        return PracticeExamScreen(
          subject: args['subject']?.toString() ?? '',
          grade: args['grade']?.toString() ?? '',
          practiceExamController: args['controller'] ?? Get.put(PracticeExamController()),
        );
      },
      middlewares: [RoleMiddleware('USER')],
    ),
    GetPage(
      name: AppRoutes.practiceExamDetail,
      page: () {
        final args = Get.arguments ?? {};
        return PracticeExamDetailScreen(fileName: args['fileName']);
      },
      middlewares: [RoleMiddleware('USER')],
    ),
    GetPage(
      name: AppRoutes.solveExercisesDetail,
      page: () {
        final arguments = Get.arguments;
        final lessonId = arguments['lessonId'];
        return SolveExercisesDetailScreen(lessonId: lessonId);
      },
      middlewares: [RoleMiddleware('USER')],
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
      middlewares: [RoleMiddleware('USER')],
    ),
    GetPage(
      name: AppRoutes.quiz,
      page: () => const QuizScreen(),
      middlewares: [RoleMiddleware('USER')],
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
          quizId: args['quizId'] ?? 0,
        );
      },
      middlewares: [RoleMiddleware('USER')],
    ),
    GetPage(
      name: AppRoutes.quizHistory,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return QuizHistoryScreen(quizId: args['quizId']);
      },
      middlewares: [RoleMiddleware('USER')],
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => SearchScreen(),
      middlewares: [RoleMiddleware('USER')],
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => DashboardScreen(),
      transition: Transition.fadeIn,
      middlewares: [RoleMiddleware('USER')],
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => const RootShell(), // <<—— DÙNG ROOTSHELL Ở ĐÂY
    ),
  ];
}
