import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_elearning_application/app/routes/app_routes.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formkeyLogin = GlobalKey<FormState>();
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      // Dùng addPostFrameCallback để tránh lỗi "setState during build"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (arguments['email'] != null) {
          authController.emailController.text = arguments['email'];
        }
        if (arguments['password'] != null) {
          authController.passwordController.text = arguments['password'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20.sp,
            color: Colors.black,
          ),
        ),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Form(
          key: _formkeyLogin,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            "Đăng Nhập",
                            style: TextStyle(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30.h),

                      // Email Field
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.w),
                        child: TextFormField(
                          controller: authController.emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            labelStyle: TextStyle(fontSize: 14.sp),
                            prefixIcon: Icon(Icons.email, size: 20.sp),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                          ),
                          style: TextStyle(fontSize: 14.sp),
                          validator: (value) {
                            return authController.validateEmail(value);
                          },
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Password Field
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.w),
                        child: Obx(
                              () => TextFormField(
                            controller: authController.passwordController,
                            obscureText:
                            !authController.isPasswordVisible.value,
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: TextStyle(fontSize: 14.sp),
                              prefixIcon: Icon(Icons.lock, size: 20.sp),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  authController.isPasswordVisible.value =
                                  !authController.isPasswordVisible.value;
                                },
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
                              return authController.validatePassword(value);
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // Forgot Password
                      Padding(
                        padding: EdgeInsets.only(right: 40.w),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Get.toNamed(AppRoutes.forgotPassword);
                            },
                            child: Text(
                              "Quên mật khẩu?",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30.h),

                      // Login Button
                      Obx(
                            () => authController.isLoading.value
                            ? CircularProgressIndicator(strokeWidth: 2.w)
                            : Padding(
                          padding:
                          EdgeInsets.symmetric(horizontal: 40.w),
                          child: Container(
                            padding:
                            EdgeInsets.only(top: 3.h, left: 3.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50.r),
                              border: Border.all(color: Colors.black),
                            ),
                            child: MaterialButton(
                              minWidth: double.infinity,
                              height: 60.h,
                              onPressed: () {
                                if (_formkeyLogin.currentState!
                                    .validate()) {
                                  authController
                                      .loginUser(_formkeyLogin);
                                }
                              },
                              color: Colors.green,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(50.r),
                              ),
                              child: Text(
                                "Đăng nhập",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Bạn chưa có tài khoản ",
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          GestureDetector(
                            onTap: () {
                              authController.usernameController.clear();
                              authController.emailController.clear();
                              authController.passwordController.clear();
                              Get.toNamed(AppRoutes.signup);
                            },
                            child: Text(
                              "Đăng Ký",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
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
