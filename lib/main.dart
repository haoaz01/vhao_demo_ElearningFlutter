import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:device_preview/device_preview.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bindings/app_bindings.dart';
import 'controllers/auth_controller.dart';
import 'controllers/main_controller.dart';
import 'app/routes/app_page.dart';
import 'app/routes/app_routes.dart';
import 'controllers/progress_controller.dart';
import 'controllers/quiz_controller.dart';
import 'controllers/quiz_history_controller.dart';
import 'controllers/streak_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isFirstOpen = prefs.getBool('isFirstOpen') ?? true;
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  Get.put(MainController());
  // Get.put(AuthController());
  Get.put(MainController());
  Get.put(ProgressController());
  Get.put(QuizHistoryController(), permanent: true); // ❗ thêm dòng này
  // Get.put(QuizController());
  Get.put<AuthController>(AuthController(), permanent: true);
  Get.put<QuizController>(QuizController(), permanent: true); // 🔑 cần dòng này


  String initialRoute;
  if (isFirstOpen) {
    initialRoute = AppRoutes.welcome;
  } else {
    initialRoute = isLoggedIn ? AppRoutes.main : AppRoutes.login;
  }

  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({required this.initialRoute, super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetMaterialApp(
          useInheritedMediaQuery: true,
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          initialBinding: AppBindings(),
          debugShowCheckedModeBanner: false,
          title: 'E-Learning App',
          initialRoute: initialRoute,
          getPages: AppPages.routes,
          theme: ThemeData(
            primaryColor: const Color(0xFF4CAF50),
            fontFamily: 'Inter',
          ),
        );
      },
    );
  }
}
