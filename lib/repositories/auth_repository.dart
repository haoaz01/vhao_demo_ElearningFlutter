import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class AuthRepository {
  static const String baseUrl = "http://192.168.0.144:8080/api/auth";

  // Headers chung cho các request
  static Map<String, String> getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Xử lý lỗi HTTP
  static Map<String, dynamic> handleError(dynamic e) {
    Get.snackbar(
      "Lỗi kết nối",
      "Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    return {'success': false, 'message': 'Network error: ${e.toString()}'};
  }

// Đăng ký tài khoản
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username, // Thêm username parameter
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: getHeaders(),
        body: json.encode({
          'email': email,
          'password': password,
          'username': username, // Gửi username đến backend
        }),
      );

      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      return handleError(e);
    }
  }

  // Đăng nhập
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: getHeaders(),
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      return handleError(e);
    }
  }

  // Quên mật khẩu
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: getHeaders(),
        body: json.encode({'email': email}),
      );

      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      return handleError(e);
    }
  }

  // Reset mật khẩu
  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      print('Gửi yêu cầu reset password: token=$token, newPassword=$newPassword');

      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: getHeaders(),
        body: json.encode({'token': token, 'newPassword': newPassword}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      print('Lỗi reset password: $e');
      return {'success': false, 'message': 'Lỗi hệ thống'};
    }
  }

  // Lấy thông tin user
  static Future<Map<String, dynamic>> getUserProfile({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-profile'),
        headers: getHeaders(token: token),
      );

      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      return handleError(e);
    }
  }

  // Cập nhật thông tin user
  static Future<Map<String, dynamic>> updateUserProfile({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user-profile'),
        headers: getHeaders(token: token),
        body: json.encode(userData),
      );

      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      return handleError(e);
    }
  }

  // Đổi mật khẩu
  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: getHeaders(token: token),
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      return handleError(e);
    }
  }

  // Kiểm tra token validity
  static Future<Map<String, dynamic>> validateToken({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/validate-token'),
        headers: getHeaders(token: token),
      );

      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      return handleError(e);
    }
  }
}