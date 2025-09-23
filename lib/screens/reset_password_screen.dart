import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class ResetPasswordScreen extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy token và email từ arguments 1 lần duy nhất
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final token = args['token'] ?? '';
    final email = args['email'] ?? '';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
              Icons.arrow_back_ios,
              size: 20.sp,
              color: Colors.black
          ),
        ),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(height: 30.h),

                      // Title
                      Text(
                        "Đặt lại mật khẩu",
                        style: TextStyle(
                            fontSize: 30.sp,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // Description
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.w),
                        child: Text(
                          "Vui lòng nhập mật khẩu mới của bạn",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey
                          ),
                        ),
                      ),
                      SizedBox(height: 30.h),

                      // New Password Field
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.w),
                        child: Obx(() => TextFormField(
                          controller: passwordController,
                          obscureText: !authController.isPasswordVisible.value,
                          decoration: InputDecoration(
                            labelText: "Mật khẩu mới",
                            labelStyle: TextStyle(fontSize: 14.sp),
                            prefixIcon: Icon(Icons.lock, size: 20.sp),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => authController.isPasswordVisible.value =
                              !authController.isPasswordVisible.value,
                              icon: Icon(
                                authController.isPasswordVisible.value
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: 20.sp,
                              ),
                            ),
                          ),
                          style: TextStyle(fontSize: 14.sp),
                          validator: (value) =>
                              authController.validatePassword(value),
                        )),
                      ),
                      SizedBox(height: 20.h),

                      // Confirm Password Field
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.w),
                        child: Obx(() => TextFormField(
                          controller: confirmPasswordController,
                          obscureText: !authController.isPasswordVisible.value,
                          decoration: InputDecoration(
                            labelText: "Xác nhận mật khẩu",
                            labelStyle: TextStyle(fontSize: 14.sp),
                            prefixIcon: Icon(Icons.lock, size: 20.sp),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => authController.isPasswordVisible.value =
                              !authController.isPasswordVisible.value,
                              icon: Icon(
                                authController.isPasswordVisible.value
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: 20.sp,
                              ),
                            ),
                          ),
                          style: TextStyle(fontSize: 14.sp),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Vui lòng xác nhận mật khẩu";
                            }
                            if (value != passwordController.text) {
                              return "Mật khẩu không khớp";
                            }
                            return null;
                          },
                        )),
                      ),
                      SizedBox(height: 30.h),

                      // Reset Password Button
                      Obx(
                            () => authController.isLoading.value
                            ? CircularProgressIndicator(strokeWidth: 2.w)
                            : Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.w),
                          child: MaterialButton(
                            minWidth: double.infinity,
                            height: 60.h,
                            color: Colors.green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.r)
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                print('Reset password với: token=$token, email=$email');
                                authController.resetPassword(
                                  token,
                                  email,
                                  passwordController.text.trim(),
                                );
                              }
                            },
                            child: Text(
                              "Đặt lại mật khẩu",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30.h),

                      // Bottom Image
                      Container(
                        height: 200.h,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/images/img_4.png"),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}