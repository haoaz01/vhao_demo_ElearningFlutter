import 'package:flutter/foundation.dart';
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
      enabled: !kReleaseMode,
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
      designSize: const Size(360, 800), // kích thước gốc để scale
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'E-Learning App',
          initialBinding: AppBindings(),
          initialRoute: initialRoute,
          getPages: AppPages.routes,

          // Cho phép GetMaterialApp dùng MediaQuery có sẵn (cần khi dùng DevicePreview)
          useInheritedMediaQuery: true,
          locale: DevicePreview.locale(context),

          // 🧩 Quan trọng: wrap DevicePreview.appBuilder + MediaQuery để clamp text scale
          builder: (ctx, widget) {
            final mq = MediaQuery.of(ctx);
            return DevicePreview.appBuilder(
              ctx,
              MediaQuery(
                data: mq.copyWith(
                  // tránh chữ/phím quá to ở máy bật "font size lớn" => gây overflow
                  textScaler: TextScaler.linear(
                    mq.textScaler.scale(1.0).clamp(0.85, 1.10),
                  ),
                ),
                child: widget!,
              ),
            );
          },

          theme: ThemeData(
            primaryColor: const Color(0xFF4CAF50),
            fontFamily: 'Inter',
            // có thể set default visual density nếu muốn gọn hơn
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
        );
      },
    );
  }
}
