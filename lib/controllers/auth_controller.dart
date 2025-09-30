import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../app/routes/app_routes.dart';
import '../repositories/auth_repository.dart';
import '../repositories/progress_repository.dart';

class AuthController extends GetxController {
  // Text controllers
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final resetPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // UI states
  final RxBool savingProfile = false.obs;
  final RxBool changingPassword = false.obs;
  var isPasswordVisible = true.obs;
  var isLoggedIn = false.obs;
  var isLoading = false.obs;

  // Auth states
  var email = ''.obs;
  var username = ''.obs;
  var authToken = ''.obs;
  var userId = 0.obs;
  var role = 'USER'.obs;

  // Local-only field
  var phone = ''.obs; // chỉ lưu local, không gửi backend

  // Edit profile states
  final isUpdatingProfile = false.obs;
  final isChangingPw = false.obs;

  // lớp – môn
  var classes = ["6", "7", "8", "9"].obs;
  var selectedClass = "".obs;
  var isClassSelected = false.obs;
  var subjects = <String>[].obs;

  // reset password
  var resetToken = ''.obs;

  // ============== NEW: base URL auth lấy từ ProgressRepository ==============
  String get _authBase => '${ProgressRepository.host}/api/auth';
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
    role.value = prefs.getString('role') ?? 'USER';
    selectedClass.value = prefs.getString('selectedClass') ?? '';
    isClassSelected.value = selectedClass.value.isNotEmpty;

    phone.value = prefs.getString('profile_phone') ?? '';

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

  // ============================ Auth flows ============================

  Future<void> registerUser(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    final response = await AuthRepository.register(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      username: usernameController.text.trim(),
    );
    isLoading.value = false;

    if (response['success'] == true) {
      if (response['user'] != null) {
        final userData = response['user'];
        final prefs = await SharedPreferences.getInstance();

        await prefs.setInt('userId', userData['id']);
        await prefs.setString('authToken', response['token'] ?? '');
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', userData['username'] ?? '');
        await prefs.setString('email', emailController.text.trim());
        await prefs.setString('role', 'USER');

        userId.value = userData['id'];
        authToken.value = response['token'] ?? '';
        isLoggedIn.value = true;
        username.value = userData['username'] ?? '';
        email.value = emailController.text.trim();
        role.value = 'USER';
      }

      Get.snackbar("Thành công", "Đăng ký thành công!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green, colorText: Colors.white);

      Get.offAllNamed(AppRoutes.login, arguments: {
        'email': emailController.text.trim(),
        'password': passwordController.text.trim()
      });
    } else {
      Get.snackbar("Lỗi", response['message'] ?? "Đăng ký thất bại",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> loginUser(GlobalKey<FormState> formKey,
      {String? emailArg, String? passwordArg}) async {
    final loginEmail = emailArg ?? emailController.text.trim();
    final loginPassword = passwordArg ?? passwordController.text.trim();

    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    final response = await AuthRepository.login(
      email: loginEmail,
      password: loginPassword,
    );
    isLoading.value = false;

    if (response['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', loginEmail);
      await prefs.setString('username', response['username'] ?? loginEmail.split('@')[0]);
      await prefs.setString('authToken', response['token'] ?? '');
      await prefs.setBool('isLoggedIn', true);
      await prefs.setInt('userId', response['userId']);
      await prefs.setString('role', response['role'] ?? 'USER');

      isLoggedIn.value = true;
      email.value = loginEmail;
      username.value = response['username'] ?? "Người dùng";
      authToken.value = response['token'] ?? '';
      userId.value = response['userId'] ?? 0;
      role.value = response['role'] ?? 'USER';

      Get.snackbar("Thành công", "Đăng nhập thành công!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green, colorText: Colors.white);

      emailController.clear();
      passwordController.clear();
      Get.offAllNamed(AppRoutes.main);
    } else {
      Get.snackbar("Lỗi", response['message'] ?? "Đăng nhập thất bại",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<bool> validateQuizSubmission() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final uid = prefs.getInt('userId');
    return token != null && token.isNotEmpty && uid != null && isLoggedIn.value;
  }

  void checkAuthStatus() {
    print("🔄 Current Auth Status:");
    print("   - isLoggedIn: ${isLoggedIn.value}");
    print("   - userId: ${userId.value}");
    print("   - authToken length: ${authToken.value.length}");
    print("   - role: ${role.value}");
  }

  Future<void> forgotPassword(String email) async {
    if (email.isEmpty) {
      Get.snackbar("Lỗi", "Email không được để trống",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (!GetUtils.isEmail(email)) {
      Get.snackbar("Lỗi", "Email không hợp lệ",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    final response = await AuthRepository.forgotPassword(email: email);
    isLoading.value = false;

    if (response['success'] == true) {
      resetToken.value = response['token'] ?? '';
      Get.snackbar("Thành công", "Liên kết đặt lại mật khẩu đã được gửi",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green, colorText: Colors.white);
      Get.toNamed(AppRoutes.resetPassword,
          arguments: {'token': response['token'], 'email': email});
    } else {
      Get.snackbar("Lỗi", response['message'] ?? "Không thể gửi yêu cầu",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> resetPassword(String token, String email, String newPassword) async {
    if (newPassword.isEmpty) {
      Get.snackbar("Lỗi", "Mật khẩu mới không được để trống",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    final response = await AuthRepository.resetPassword(
      token: token,
      newPassword: newPassword.trim(),
    );
    isLoading.value = false;

    if (response['success'] == true) {
      Get.snackbar("Thành công",
          "Mật khẩu đã được đặt lại. Đăng nhập bằng mật khẩu mới nhé.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green, colorText: Colors.white);
      resetPasswordController.clear();
      confirmPasswordController.clear();
      Get.offAllNamed(AppRoutes.login, arguments: {'email': email.trim()});
    } else {
      Get.snackbar("Lỗi", response['message'] ?? "Không thể đặt lại mật khẩu",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email') ?? '';

    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('authToken');
    await prefs.remove('username');
    await prefs.remove('userId');
    await prefs.remove('role');

    isLoggedIn.value = false;
    email.value = '';
    username.value = '';
    userId.value = 0;
    role.value = 'USER';
    selectedClass.value = '';
    isClassSelected.value = false;
    authToken.value = '';
    subjects.clear();

    emailController.clear();
    passwordController.clear();
    usernameController.clear();
    resetPasswordController.clear();
    confirmPasswordController.clear();

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

  Future<void> saveLocalPhone(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final v = (value ?? '').trim();
    phone.value = v;
    await prefs.setString('profile_phone', v);
  }

  // ====================== Profile APIs (dùng host/token từ ProgressRepo) ======================

  Future<String?> _getToken() => ProgressRepository.getToken();

  // GET /api/auth/user-profile
  Future<void> loadMe() async {
    final token = await _getToken();
    if (token == null) {
      Get.snackbar('Lỗi', 'Chưa đăng nhập');
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('$_authBase/user-profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final user = (json['user'] ?? {}) as Map<String, dynamic>;
        username.value = (user['username'] ?? '').toString();
        email.value = (user['email'] ?? '').toString();
      } else if (res.statusCode == 401) {
        Get.snackbar('Phiên hết hạn', 'Vui lòng đăng nhập lại');
      } else {
        Get.snackbar('Lỗi', 'Không tải được hồ sơ (${res.statusCode})');
      }
    } catch (e) {
      Get.snackbar('Lỗi mạng', e.toString());
    }
  }

  // PUT /api/auth/user-profile  (đổi tên/email, và ĐỔI MẬT KHẨU nếu kèm current/new)
  Future<void> updateMe({
    required String username,
    required String email,
    String? currentPassword,
    String? newPassword,
    String? phoneLocal, // lưu local nếu truyền vào
  }) async {
    final token = await _getToken();
    if (token == null) {
      Get.snackbar('Lỗi', 'Chưa đăng nhập');
      return;
    }

    isUpdatingProfile.value = true;
    try {
      final body = <String, dynamic>{
        'username': username,
        'email': email,
      };
      if ((currentPassword ?? '').isNotEmpty || (newPassword ?? '').isNotEmpty) {
        body['currentPassword'] = currentPassword ?? '';
        body['newPassword'] = newPassword ?? '';
      }

      final res = await http.put(
        Uri.parse('$_authBase/user-profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final user = (json['user'] ?? {}) as Map<String, dynamic>;

        this.username.value = (user['username'] ?? '').toString();
        this.email.value = (user['email'] ?? '').toString();

        // Ghi lại vào SharedPreferences để lần sau mở app vẫn thấy cập nhật
        final sp = await SharedPreferences.getInstance();
        await sp.setString('username', this.username.value);
        await sp.setString('email', this.email.value);

        // Phone chỉ local
        if (phoneLocal != null) {
          await sp.setString('profile_phone', phoneLocal);
          phone.value = phoneLocal;
        }

        Get.snackbar('Thành công', 'Cập nhật hồ sơ thành công');
      } else {
        final msg = _extractMsg(res.body);
        Get.snackbar('Thất bại', msg ?? 'Không thể cập nhật (${res.statusCode})');
        throw Exception(msg);
      }
    } finally {
      isUpdatingProfile.value = false;
    }
  }

  // Đổi mật khẩu (tách riêng nếu thích) — vẫn dùng endpoint hồ sơ theo backend bạn
  Future<void> changePassword({required String current, required String next}) async {
    await updateMe(
      username: username.value,
      email: email.value,
      currentPassword: current,
      newPassword: next,
    );
  }

  String? _extractMsg(String body) {
    try {
      final j = jsonDecode(body);
      return (j['message'] ?? j['error'])?.toString();
    } catch (_) {
      return null;
    }
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