import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final GlobalKey<FormState> _formkeyForgotPassword = GlobalKey<FormState>();
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController emailController = TextEditingController();

  ForgotPasswordScreen({super.key});

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
          key: _formkeyForgotPassword,
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
                            "Quên mật khẩu",
                            style: TextStyle(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40.w),
                            child: Text(
                              "Vui lòng nhập email của bạn để nhận liên kết đặt lại mật khẩu",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30.h),

                      // Email Field
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.w),
                        child: TextFormField(
                          controller: emailController,
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
                      SizedBox(height: 30.h),

                      // Send Request Button
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
                              if (_formkeyForgotPassword.currentState!.validate()) {
                                authController.forgotPassword(
                                  emailController.text.trim(),
                                );
                              }
                            },
                            color: Colors.green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.r),
                            ),
                            child: Text(
                              "Gửi yêu cầu",
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

                      // Back to Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Quay lại ",
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          GestureDetector(
                            onTap: () {
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