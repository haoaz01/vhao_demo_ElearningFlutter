import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/search_controller.dart';
import '../controllers/theory_controller.dart';

class AppBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<SearchController>(() => SearchController(), fenix: true);
    Get.lazyPut<TheoryController>(() => TheoryController(), fenix: true);
  }
}