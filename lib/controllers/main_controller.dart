import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainController extends GetxController {
  var currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
  }

  // Future<void> _navigateAndSetFirstOpen(String routeName) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool('isFirstOpen', false); // đánh dấu đã mở lần đầu
  //   Get.offNamed(routeName); // Sử dụng Get.offNamed để không quay lại WelcomeScreen
  // }
}
