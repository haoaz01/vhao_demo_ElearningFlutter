// repositories/search_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/lesson_model.dart';

class SearchRepository {
  final String baseUrl = 'http://192.168.0.144:8080/api/search'; // Thay bằng URL thực tế

  Future<List<Lesson>> searchLessons(String keyword, {int? subjectId, int? grade}) async {
    final Map<String, String> queryParams = {};

    if (keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }
    if (subjectId != null) {
      queryParams['subjectId'] = subjectId.toString();
    }
    if (grade != null) {
      queryParams['grade'] = grade.toString();
    }

    final uri = Uri.parse('$baseUrl/lessons').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['success'] == true) {
        final List<dynamic> lessonsJson = data['data'];
        return lessonsJson.map((json) => Lesson.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to search lessons');
      }
    } else {
      throw Exception('Failed to load search results: ${response.statusCode}');
    }
  }
}