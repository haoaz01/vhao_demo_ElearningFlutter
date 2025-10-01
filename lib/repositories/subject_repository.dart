import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../model/chapter_model.dart';
import '../model/lesson_content_model.dart';
import '../model/exercise_model.dart';
import '../model/lesson_model.dart';

class SubjectRepository {
  late final String baseUrl;
  late final http.Client client;

  SubjectRepository() {
    if (kIsWeb) {
      baseUrl = "http://192.168.1.219:8080/api";
    } else if (Platform.isAndroid) {
      if (_isGenymotion()) {
        baseUrl = "http://192.168.1.219:8080/api";
      } else if (_isEmulator()) {
        baseUrl = "http://192.168.1.219:8080/api";
      } else {
        baseUrl = "http://192.168.1.219:8080/api";
      }
    } else if (Platform.isIOS) {
      baseUrl = "http://localhost:8080/api";
    } else {
      baseUrl = "http://192.168.1.219:8080/api";
    }

    print("Using baseUrl: $baseUrl");
    client = _createHttpClient();
  }

  http.Client _createHttpClient() {
    if (kIsWeb) return http.Client();

    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 30)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    return IOClient(httpClient);
  }

  bool _isEmulator() {
    return Platform.isAndroid &&
        (Platform.environment.containsKey('EMULATOR_DEVICE') ||
            Platform.environment.containsKey('ANDROID_EMULATOR'));
  }

  bool _isGenymotion() {
    return Platform.isAndroid &&
        Platform.environment.containsKey('GENYMOTION');
  }

  String _normalizeSubjectCode(String subjectName) {
    final mapping = {
      "Toán": "toan",
      "Ngữ Văn": "nguvan",
      "Khoa học Tự nhiên": "khoahoctunhien",
      "Tiếng Anh": "tienganh",
    };
    return mapping[subjectName] ?? subjectName.toLowerCase().replaceAll(" ", "");
  }

  Future<String> _getWithRetry(String url, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        print("Calling API (attempt ${i + 1}/$maxRetries): $url");
        final response =
        await client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          throw Exception("Lỗi server: ${response.statusCode} khi gọi $url");
        }
        return response.body;
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        print("Retrying API call after error: $e");
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception("Failed to call API after $maxRetries attempts");
  }

  /// ✅ Lấy danh sách ContentItem của lesson
  Future<List<LessonContent>> getLessonContents(int lessonId) async {
    try {
      final url = "$baseUrl/lessons/$lessonId/contents";
      final res = await _getWithRetry(url);
      final List<dynamic> jsonList = json.decode(res);
      final list = jsonList
          .map((x) => LessonContent.fromJson(x))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return list;
    } catch (e) {
      print("Error fetching lesson contents: $e");
      return [];
    }
  }

  /// Tối ưu hóa: Lấy lessons với đầy đủ thông tin (bao gồm cả contents nếu có)
  Future<List<Lesson>> getLessonsWithContents(int chapterId) async {
    try {
      final url = "$baseUrl/chapters/$chapterId/lessons";
      final res = await _getWithRetry(url);
      final List<dynamic> jsonList = json.decode(res);

      List<Lesson> lessons = [];
      for (var lessonJson in jsonList) {
        Lesson lesson = Lesson.fromJson(lessonJson);

        // Nếu lesson chưa có contents, fetch thêm
        if (lesson.contents.isEmpty) {
          final contents = await getLessonContents(lesson.id);
          lesson = lesson.copyWith(contents: contents);
        }

        lessons.add(lesson);
      }

      return lessons;
    } catch (e) {
      print("Error fetching lessons with contents: $e");
      return [];
    }
  }

  /// Ví dụ: fetch theory (chapters + lessons + contents + exercises)
  Future<List<Chapter>> fetchTheory(String subjectName, int grade) async {
    try {
      final subjectCode = _normalizeSubjectCode(subjectName);

      // Lấy subject theo grade + code
      final subjectRes = await _getWithRetry("$baseUrl/grades/$grade/subjects/$subjectCode");
      final subjectData = json.decode(subjectRes);

      if (subjectData == null || subjectData['id'] == null) {
        throw Exception("Không tìm thấy môn học: $subjectName - Khối $grade");
      }

      final subjectId = subjectData['id'];

      // Lấy danh sách chapters
      final chaptersRes = await _getWithRetry("$baseUrl/subjects/$subjectId/chapters");
      final chaptersJson = json.decode(chaptersRes) as List;

      List<Chapter> chapters = [];

      for (var chapterJson in chaptersJson) {
        final chapterId = chapterJson['id'];

        // Sử dụng phương thức tối ưu để lấy lessons với contents
        List<Lesson> lessons = await getLessonsWithContents(chapterId);

        // Lấy exercises của từng lesson
        for (int i = 0; i < lessons.length; i++) {
          final lesson = lessons[i];

          // Debug: In ra thông tin lesson
          print("Loading exercises for lesson: ${lesson.id} - ${lesson.title}");

          final exercisesRes = await _getWithRetry("$baseUrl/lessons/${lesson.id}/exercises");
          final exercisesJson = json.decode(exercisesRes) as List;

          // Debug: In ra số lượng exercises
          print("Found ${exercisesJson.length} exercises for lesson ${lesson.id}");

          List<Exercise> exercises = [];

          for (var exJson in exercisesJson) {
            Exercise exercise = Exercise.fromJson(exJson);

            // Lấy solutions của exercise
            final solutionsRes = await _getWithRetry("$baseUrl/exercises/${exercise.id}/solutions");
            final solutionsJson = json.decode(solutionsRes) as List;

            // Debug: In ra số lượng solutions
            print("Found ${solutionsJson.length} solutions for exercise ${exercise.id}");

            final solutions = solutionsJson.map((x) => ExerciseSolution.fromJson(x)).toList();

            exercise = exercise.copyWith(solutions: solutions);
            exercises.add(exercise);
          }

          // Tạo lesson mới với exercises và cập nhật vào danh sách
          lessons[i] = lesson.copyWith(exercises: exercises);
        }

        Chapter chapter = Chapter.fromJson(chapterJson);
        chapter.lessons = lessons;
        chapters.add(chapter);
      }

      return chapters;
    } catch (e) {
      print("ERROR: Không thể tải dữ liệu từ API: $e");
      throw Exception("Không thể tải dữ liệu từ API: $e");
    }
  }

  void dispose() {
    client.close();
  }
}