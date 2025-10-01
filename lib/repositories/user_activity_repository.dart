import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/accumulate_session_response_model.dart';
import '../model/check_studied_response_model.dart';
import '../model/streak_info_model.dart';
import '../model/today_info_response_model.dart';
import '../model/user_activity_dto_model.dart';
import '../model/user_streak_response_model.dart';

class UserActivityRepository {
  // static const String baseUrl = 'http://192.168.1.148:8080/api/user-activity';
  static const String baseUrl = 'http://192.168.1.148:8080/api/user-activity';


  final http.Client client;

  UserActivityRepository({required this.client});

  // 1. Ghi nhận activity mới (cộng dồn)
  Future<UserActivityDTO> recordActivity(int userId, DateTime activityDate, int additionalMinutes) async {
    try {
      final url = Uri.parse('$baseUrl'); // POST chuẩn, params trong body
      print('📝 POST recordActivity: $url');

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'userId': userId.toString(),
          'activityDate': _formatDate(activityDate),
          'additionalMinutes': additionalMinutes.toString(),
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

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

  // 2. Cộng dồn thời gian session (ENDPOINT MỚI)
  Future<AccumulateSessionResponse> accumulateSessionTime({
    required int userId,
    required DateTime activityDate,
    required int sessionMinutes,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/accumulate-session');
      print('📝 POST accumulateSessionTime: $url');

      final body = {
        'userId': userId.toString(),
        'activityDate': _formatDate(activityDate),
        'sessionMinutes': sessionMinutes.toString(),
      };

      final response = await client.post(
        url,
        body: body,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ).timeout(const Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          return AccumulateSessionResponse.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Unknown error from server');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Repository error in accumulateSessionTime: $e');
      rethrow;
    }
  }
  // 3. Lấy thông tin streak cơ bản (ENDPOINT MỚI)
  Future<StreakInfo> getStreakInfo(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/streak/${userId.toString()}');
      print('🔄 GET getStreakInfo: $url');

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

        if (data['success'] == true) {
          // ⚠️ Backend không có "data", parse trực tiếp
          return StreakInfo.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Unknown error from server');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Repository error in getStreakInfo: $e');
      rethrow;
    }
  }

  // 4. Lấy thông tin streak và calendar
  Future<UserStreakResponse> getUserStreakAndCalendar(int userId, {int months = 3}) async {
    try {
      final url = Uri.parse('$baseUrl/streak-calendar/${userId.toString()}?months=$months');
      print('🔄 GET getUserStreakAndCalendar: $url');

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
        print('=== DEBUG STREAK CALENDAR RESPONSE ===');
        print('Success: ${data['success']}');
        print('Message: ${data['message']}');
        print('Data type: ${data['data']?.runtimeType}');
        if (data['data'] != null) {
          print('Data keys: ${(data['data'] as Map).keys.toList()}');
          print('Calendar days count: ${data['data']['calendarDays']?.length ?? 0}');
        }
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

  // 5. Lấy thông tin hôm nay (ENDPOINT MỚI)
  Future<TodayInfoResponse> getTodayInfo(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/${userId.toString()}/today');
      print('🔄 GET getTodayInfo: $url');

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

        if (data['success'] == true) {
          return TodayInfoResponse.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Unknown error from server');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Repository error in getTodayInfo: $e');
      rethrow;
    }
  }

  // 6. Lấy tổng thời gian theo ngày (ENDPOINT MỚI)
  Future<TodayInfoResponse> getTotalMinutesByDate(int userId, DateTime date) async {
    try {
      final url = Uri.parse('$baseUrl/${userId.toString()}/total-minutes/${_formatDate(date)}');
      print('🔄 GET getTotalMinutesByDate: $url');

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

        if (data['success'] == true) {
          return TodayInfoResponse.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Unknown error from server');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Repository error in getTotalMinutesByDate: $e');
      rethrow;
    }
  }

  // 7. Kiểm tra trạng thái học (ENDPOINT MỚI)
  Future<CheckStudiedResponse> checkIfStudiedDay(int userId, DateTime date) async {
    try {
      final url = Uri.parse('$baseUrl/${userId.toString()}/check-studied/${_formatDate(date)}');
      print('🔄 GET checkIfStudiedDay: $url');

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

        if (data['success'] == true) {
          return CheckStudiedResponse.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Unknown error from server');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Repository error in checkIfStudiedDay: $e');
      rethrow;
    }
  }

  // 8. Lấy activity theo ngày (ENDPOINT MỚI)
  Future<UserActivityDTO?> getActivityByDate(int userId, DateTime date) async {
    try {
      final url = Uri.parse('$baseUrl/${userId.toString()}/date/${_formatDate(date)}');
      print('🔄 GET getActivityByDate: $url');

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

        if (data['success'] == true) {
          if (data['data'] == null) {
            return null; // Không có activity cho ngày này
          }
          return UserActivityDTO.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Unknown error from server');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Repository error in getActivityByDate: $e');
      rethrow;
    }
  }


  // THÊM PHƯƠNG THỨC KIỂM TRA KẾT NỐI CHI TIẾT
  Future<Map<String, dynamic>> testConnectionDetailed() async {
    try {
      final url = Uri.parse('$baseUrl/streak-calendar/1?months=1'); // Test đúng API mà Streak screen dùng
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