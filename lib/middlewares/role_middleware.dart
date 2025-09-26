import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../app/routes/app_routes.dart';

class RoleMiddleware extends GetMiddleware {
  final String requiredRole;

  RoleMiddleware(this.requiredRole);

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    if (!authController.isLoggedIn.value) {
      return const RouteSettings(name: AppRoutes.login);
    }

    if (authController.role.value != requiredRole) {
      // Nếu không đúng role thì cho quay về main
      return const RouteSettings(name: AppRoutes.main);
    }

    return null;
  }
}
