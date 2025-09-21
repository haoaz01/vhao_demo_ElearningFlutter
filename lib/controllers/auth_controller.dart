import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/routes/app_routes.dart';
import '../repositories/auth_repository.dart';

class AuthController extends GetxController {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final resetPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isPasswordVisible = true.obs;
  var isLoggedIn = false.obs;
  var isLoading = false.obs;

  var email = ''.obs;
  var username = ''.obs;
  var authToken = ''.obs;
  var userId = 0.obs;

  var classes = ["6", "7", "8", "9"].obs;
  var selectedClass = "".obs;
  var isClassSelected = false.obs;

  var subjects = <String>[].obs;

  // Biến để lưu token reset mật khẩu
  var resetToken = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn.value = prefs.getBool('isLoggedIn') ?? false;
    authToken.value = prefs.getString('authToken') ?? '';
    email.value = prefs.getString('email') ?? '';
    username.value = prefs.getString('username') ?? 'Người dùng';
    userId.value = prefs.getInt('userId') ?? 0;
    selectedClass.value = prefs.getString('selectedClass') ?? '';
    isClassSelected.value = selectedClass.value.isNotEmpty;

    print("🔑 Load userId from prefs: ${userId.value}");

    if (isLoggedIn.value) {
      updateSubjects();
    }
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) return "Tên không được để trống";
    if (value.length < 3) return "Tên phải có ít nhất 3 ký tự";
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email không được để trống";
    if (!GetUtils.isEmail(value)) return "Email không hợp lệ";
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Mật khẩu không được để trống";
    if (value.length < 6) return "Mật khẩu phải có ít nhất 6 ký tự";
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return "Xác nhận mật khẩu không được để trống";
    if (value != passwordController.text) return "Mật khẩu xác nhận không khớp";
    return null;
  }

  Future<void> registerUser(GlobalKey<FormState> formKey) async {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;

      final response = await AuthRepository.register(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        username: usernameController.text.trim(), // Thêm username
      );

      isLoading.value = false;

      if (response['success'] == true) {
        // Lưu thông tin user từ response, bao gồm ID
        if (response['user'] != null) {
          final userData = response['user'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', userData['id']);
          userId.value = userData['id'];
          username.value = userData['username'] ?? '';
        }

        Get.snackbar(
          "Thành công",
          "Đăng ký thành công!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Tự động điền thông tin đăng nhập sau khi đăng ký thành công
        Get.offAllNamed(AppRoutes.login, arguments: {
          'email': emailController.text.trim(),
          'password': passwordController.text.trim()
        });
      } else {
        Get.snackbar(
          "Lỗi",
          response['message'] ?? "Đăng ký thất bại",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> loginUser(GlobalKey<FormState> formKey, {String? emailArg, String? passwordArg}) async {
    final loginEmail = emailArg ?? emailController.text.trim();
    final loginPassword = passwordArg ?? passwordController.text.trim();

    if (formKey.currentState!.validate()) {
      isLoading.value = true;

      final response = await AuthRepository.login(
        email: loginEmail,
        password: loginPassword,
      );

      isLoading.value = false;

      if (response['success'] == true) {
        // Lưu thông tin đăng nhập vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', loginEmail);
        await prefs.setString('username', response['username'] ?? loginEmail.split('@')[0]);
        await prefs.setString('authToken', response['token'] ?? '');
        await prefs.setBool('isLoggedIn', true);
        await prefs.setInt('userId', response['userId']); // 🔑 Lưu userId

        // Cập nhật state
        isLoggedIn.value = true;
        email.value = loginEmail;
        username.value = response['username'] ?? "Người dùng";
        authToken.value = response['token'] ?? '';
        userId.value = response['userId'] ?? 0;

        print("✅ Login success - userId: ${userId.value}");

        Get.snackbar(
          "Thành công",
          "Đăng nhập thành công!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Clear form và chuyển đến màn hình chính
        emailController.clear();
        passwordController.clear();
        Get.offAllNamed(AppRoutes.main);
      } else {
        Get.snackbar(
          "Lỗi",
          response['message'] ?? "Đăng nhập thất bại",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  // Phương thức quên mật khẩu
  Future<void> forgotPassword(String email) async {
    if (email.isEmpty) {
      Get.snackbar(
        "Lỗi",
        "Email không được để trống",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (!GetUtils.isEmail(email)) {
      Get.snackbar(
        "Lỗi",
        "Email không hợp lệ",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    final response = await AuthRepository.forgotPassword(email: email);

    isLoading.value = false;

    if (response['success'] == true) {
      resetToken.value = response['token'] ?? '';
      Get.snackbar(
        "Thành công",
        "Liên kết đặt lại mật khẩu đã được gửi",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.toNamed(
        AppRoutes.resetPassword,
        arguments: {'token': response['token'], 'email': email},
      );
    } else {
      Get.snackbar(
        "Lỗi",
        response['message'] ?? "Không thể gửi yêu cầu",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Phương thức reset mật khẩu
  Future<void> resetPassword(String token, String email, String newPassword) async {
    if (newPassword.isEmpty) {
      Get.snackbar(
        "Lỗi",
        "Mật khẩu mới không được để trống",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      print('Bắt đầu reset password');
      print('Token: $token, Email: $email, New password: $newPassword');

      final response = await AuthRepository.resetPassword(
        token: token,
        newPassword: newPassword.trim(),
      );

      isLoading.value = false;

      print('Kết quả reset: ${response['success']}');
      print('Thông điệp: ${response['message']}');

      if (response['success'] == true) {
        Get.snackbar(
          "Thành công",
          "Mật khẩu đã được đặt lại thành công. Vui lòng đăng nhập lại bằng mật khẩu mới.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        resetPasswordController.clear();
        confirmPasswordController.clear();

        // Chuyển đến login và truyền email
        Get.offAllNamed(AppRoutes.login, arguments: {'email': email.trim()});
      } else {
        Get.snackbar(
          "Lỗi",
          response['message'] ?? "Không thể đặt lại mật khẩu",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        "Lỗi",
        "Đã có lỗi xảy ra: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Lưu email trước khi xóa để hiển thị trên màn hình login
    final savedEmail = prefs.getString('email') ?? '';

    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('authToken');
    await prefs.remove('username');
    await prefs.remove('userId');

    isLoggedIn.value = false;
    email.value = '';
    username.value = '';
    userId.value = 0;
    selectedClass.value = '';
    isClassSelected.value = false;
    authToken.value = '';

    // Giữ selectedClass và isClassSelected
    selectedClass.value = prefs.getString('selectedClass') ?? '';
    isClassSelected.value = selectedClass.value.isNotEmpty;
    subjects.clear();

    // Clear tất cả các controller
    emailController.clear();
    passwordController.clear();
    usernameController.clear();
    resetPasswordController.clear();
    confirmPasswordController.clear();

    // Chuyển đến màn hình login và truyền email đã lưu
    Get.offAllNamed(AppRoutes.login, arguments: {'email': savedEmail});
  }

  Future<void> setSelectedClass(String value) async {
    selectedClass.value = value;
    isClassSelected.value = true;
    updateSubjects();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedClass', value);
    subjects.refresh();
  }

  void updateSubjects() {
    subjects.value = ["Toán", "Khoa Học Tự Nhiên", "Tiếng Anh", "Ngữ Văn"];
  }

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    resetPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}