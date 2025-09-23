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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isFirstOpen = prefs.getBool('isFirstOpen') ?? true;
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Khởi tạo các controller
  Get.put(AuthController());
  Get.put(MainController());

  // Quyết định initialRoute dựa trên isFirstOpen trước
  String initialRoute;
  if (isFirstOpen) {
    initialRoute = AppRoutes.welcome; // lần đầu mở app
  } else {
    initialRoute = isLoggedIn ? AppRoutes.main : AppRoutes.login;
  }

  runApp(
    DevicePreview(
      // enabled: kDebugMode && !kIsWeb,
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
      designSize: const Size(360, 800), // Galaxy A21s logical size
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