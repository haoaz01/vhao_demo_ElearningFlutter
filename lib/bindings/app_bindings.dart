import 'package:get/get.dart';
import 'package:http/http.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_flow_controller.dart';
import '../controllers/progress_controller.dart';
import '../controllers/quiz_controller.dart';
import '../controllers/quiz_history_controller.dart';
import '../controllers/search_controller.dart';
import '../controllers/theory_controller.dart';
import '../controllers/user_activity_controller.dart';
import '../repositories/user_activity_repository.dart';

class AppBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<SearchController>(() => SearchController(), fenix: true);
    Get.lazyPut<TheoryController>(() => TheoryController(), fenix: true);
    Get.lazyPut<ProgressController>(() => ProgressController(), fenix: true);
    Get.lazyPut<QuizController>(() => QuizController(), fenix: true); // đủ
    Get.lazyPut<QuizHistoryController>(() => QuizHistoryController(), fenix: true); // đủ 
    Get.lazyPut<Client>(() => Client(),fenix: true);
    // Repo + Controller cho User Activity
    Get.lazyPut<UserActivityRepository>(
          () => UserActivityRepository(client: Get.find()),
      fenix: true,
    );
    Get.lazyPut<UserActivityController>(
            () => UserActivityController(repository: Get.find()),
        fenix: true,);
    Get.put<AuthFlowController>(AuthFlowController(), permanent: true);
  }

}