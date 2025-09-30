import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/user_activity_dto.dart';
import '../model/user_streak_response.dart';

class UserActivityRepository {
  // static const String baseUrl = 'http://192.168.1.219:8080/api/user-activity';
  static const String baseUrl = 'http://10.0.2.2:8080/api/user-activity';

  final http.Client client;

  UserActivityRepository({required this.client});

  Future<UserActivityDTO> recordActivity(int userId, DateTime activityDate, int additionalMinutes) async {
    try {
      // CHUYỂN userId THÀNH String ĐỂ TRÁNH LỖI TYPE
      final url = Uri.parse('$baseUrl?userId=${userId.toString()}&activityDate=${_formatDate(activityDate)}&additionalMinutes=$additionalMinutes');
      print('📝 POST: $url');

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('🔍 Response data: $data');

        if (data['success'] == true) {
          if (data['data'] == null) {
            throw Exception('Server returned success but data is null');
          }
          return UserActivityDTO.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Unknown error from server');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Repository error in recordActivity: $e');
      rethrow;
    }
  }

  Future<UserStreakResponse> getUserStreakAndCalendar(int userId, {int months = 3}) async {
    try {
      // CHUYỂN userId THÀNH String
      final url = Uri.parse('$baseUrl/streak/${userId.toString()}?months=$months');
      print('🔄 GET: $url');

      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // DEBUG CHI TIẾT
        print('=== DEBUG API RESPONSE ===');
        print('Success: ${data['success']}');
        print('Message: ${data['message']}');
        print('Data type: ${data['data']?.runtimeType}');
        print('Data keys: ${data['data'] != null ? (data['data'] as Map).keys.toList() : "null"}');
        print('========================');

        if (data['success'] == true) {
          if (data['data'] == null) {
            throw Exception('Server returned success but data is null');
          }
          return UserStreakResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Unknown error from server');
        }
      } else if (response.statusCode == 404) {
        throw Exception('API endpoint not found (404). Check server URL.');
      } else if (response.statusCode == 500) {
        throw Exception('Server error (500). Check server logs.');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Repository error in getUserStreakAndCalendar: $e');
      rethrow;
    }
  }

  // THÊM PHƯƠNG THỨC KIỂM TRA KẾT NỐI CHI TIẾT
  Future<Map<String, dynamic>> testConnectionDetailed() async {
    try {
      final url = Uri.parse('$baseUrl/streak/1?months=1'); // Test với user ID 1
      print('🔍 Testing connection to: $url');

      final response = await client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      final result = {
        'connected': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': response.reasonPhrase,
        'body': response.body,
      };

      print('🔍 Connection test result: $result');
      return result;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return {
        'connected': false,
        'error': e.toString(),
      };
    }
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T')[0]; // yyyy-MM-dd
  }
}