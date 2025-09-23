import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class SignupScreen extends StatelessWidget {
  final GlobalKey<FormState> _formkeySignup = GlobalKey<FormState>();
  final AuthController authController = Get.find<AuthController>();

  SignupScreen({super.key});

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
              color: Colors.black
          ),
        ),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Form(
          key: _formkeySignup,
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
                            "Đăng Ký",
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

                      // Username Field
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.w),
                        child: TextFormField(
                          controller: authController.usernameController,
                          decoration: InputDecoration(
                            labelText: "Username",
                            labelStyle: TextStyle(fontSize: 14.sp),
                            prefixIcon: Icon(Icons.person, size: 20.sp),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                          ),
                          style: TextStyle(fontSize: 14.sp),
                          validator: (value) {
                            return authController.validateName(value);
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
                            obscureText: !authController.isPasswordVisible.value,
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
                      SizedBox(height: 30.h),

                      // Register Button
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.w),
                        child: Container(
                          padding: EdgeInsets.only(top: 3.h, left: 3.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50.r),
                            border: Border.all(color: Colors.black),
                          ),
                          child: MaterialButton(
                            minWidth: double.infinity,
                            height: 60.h,
                            onPressed: () {
                              if (_formkeySignup.currentState!.validate()) {
                                authController.registerUser(_formkeySignup);
                              }
                            },
                            color: Colors.green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.r),
                            ),
                            child: Text(
                              "Đăng ký",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Bạn đã có tài khoản? ",
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          GestureDetector(
                            onTap: () {
                              authController.usernameController.clear();
                              authController.emailController.clear();
                              authController.passwordController.clear();
                              Get.toNamed('/login');
                            },
                            child: Text(
                              "Đăng Nhập",
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