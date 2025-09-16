import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

import '../model/chapter_model.dart';
import '../repositories/subject_repository.dart';

class TheoryController extends GetxController {
  final SubjectRepository repository = SubjectRepository();
  final RxBool isLoading = false.obs;
  final RxList<Chapter> chapters = <Chapter>[].obs;
  final RxMap<String, Set<String>> completedLessonsBySubject = <String, Set<String>>{}.obs;
  final Connectivity connectivity = Connectivity();
  final RxMap<String, double> _progressBySubject = <String, double>{}.obs;

  late String subject; // tên hiển thị (VD: Toán, Ngữ Văn, Tiếng Anh)
  late int grade;      // khối lớp

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments ?? {};
    subject = args['subject'] ?? 'Toán';
    grade = args['grade'] ?? 6;

    _loadAllCompletedLessons();
    loadTheory(subject, grade);

    // Listen for changes in completed lessons and update progress for all subjects
    ever(completedLessonsBySubject, (_) => _updateAllProgress());
  }

  @override
  void onClose() {
    repository.dispose();
    super.onClose();
  }

  /// Map tên môn học sang subject code trong DB
  String _mapSubjectToCode(String subject) {
    switch (subject.trim().toLowerCase()) {
      case 'toán':
        return 'toan';
      case 'ngữ văn':
      case 'văn':
        return 'nguvan';
      case 'tiếng anh':
      case 'anh':
        return 'tienganh';
      case 'khoa học tự nhiên':
      case 'khoahoctunhien':
        return 'khoahoctunhien';
      default:
        throw Exception("Môn học không hợp lệ: $subject");
    }
  }

  String _getStorageKey(String subject, int grade) {
    return 'completedLessons_${_mapSubjectToCode(subject)}_$grade';
  }

  String _getProgressKey(String subject, int grade) {
    return 'progress_${_mapSubjectToCode(subject)}_$grade';
  }

  /// Kiểm tra kết nối mạng và khả năng kết nối đến server
  Future<bool> checkNetworkConnection() async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    try {
      final result = await InternetAddress.lookup('192.168.0.144');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }

    return false;
  }

  /// Load chapters + lessons từ API
  Future<void> loadTheory(String subject, int grade) async {
    try {
      isLoading.value = true;

      final hasNetwork = await checkNetworkConnection();
      if (!hasNetwork) {
        Get.snackbar(
          'Lỗi kết nối',
          'Không có kết nối mạng hoặc không thể kết nối đến server.',
          duration: const Duration(seconds: 3),
        );
        isLoading.value = false;
        return;
      }

      final subjectCode = _mapSubjectToCode(subject);
      final theoryData = await repository.fetchTheory(subjectCode, grade);

      chapters.value = theoryData;
      _updateProgress(subject, grade); // Update progress after loading chapters
    } catch (e) {
      print("Error loading theory: $e");
      Get.snackbar(
        'Lỗi tải dữ liệu',
        'Không thể tải dữ liệu cho môn $subject.\n'
            'Vui lòng kiểm tra:\n'
            '1. Thiết bị đã kết nối cùng mạng WiFi\n'
            '2. Địa chỉ IP server chính xác\n'
            '3. Server đang chạy',
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load tất cả các bài học đã hoàn thành từ SharedPreferences
  Future<void> _loadAllCompletedLessons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      for (var key in allKeys) {
        if (key.startsWith('completedLessons_')) {
          final saved = prefs.getStringList(key) ?? [];
          completedLessonsBySubject[key] = saved.toSet();
        }
      }
      _updateAllProgress(); // Update progress for all subjects after loading completed lessons
    } catch (e) {
      print("Error loading completed lessons: $e");
    }
  }

  /// Lưu lại danh sách bài học hoàn thành cho môn học và khối cụ thể
  Future<void> _saveCompletedLessons(String subject, int grade) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(subject, grade);
      await prefs.setStringList(key, completedLessonsBySubject[key]?.toList() ?? []);
    } catch (e) {
      print("Error saving completed lessons: $e");
    }
  }

  /// Toggle trạng thái hoàn thành cho bài học
  void toggleComplete(String subject, int grade, String lessonTitle) {
    final key = _getStorageKey(subject, grade);

    if (!completedLessonsBySubject.containsKey(key)) {
      completedLessonsBySubject[key] = <String>{};
    }

    if (completedLessonsBySubject[key]!.contains(lessonTitle)) {
      completedLessonsBySubject[key]!.remove(lessonTitle);
    } else {
      completedLessonsBySubject[key]!.add(lessonTitle);
    }

    _saveCompletedLessons(subject, grade);
    completedLessonsBySubject.refresh(); // Force UI update
    _updateProgress(subject, grade); // Update progress after toggling completion
  }

  /// Kiểm tra xem bài học đã hoàn thành hay chưa
  bool isCompleted(String subject, int grade, String lessonTitle) {
    final key = _getStorageKey(subject, grade);
    return completedLessonsBySubject[key]?.contains(lessonTitle) ?? false;
  }

  /// Cập nhật tiến độ hoàn thành cho tất cả các môn học
  void _updateAllProgress() {
    // Get all unique subject-grade combinations from completed lessons
    final allKeys = completedLessonsBySubject.keys.toList();

    for (var key in allKeys) {
      // Extract subject and grade from key (format: completedLessons_subject_grade)
      final parts = key.split('_');
      if (parts.length >= 3) {
        final subjectCode = parts[1];
        final grade = int.tryParse(parts[2]);

        if (grade != null) {
          // Convert subject code back to subject name
          String subjectName;
          switch (subjectCode) {
            case 'toan':
              subjectName = 'Toán';
              break;
            case 'nguvan':
              subjectName = 'Ngữ Văn';
              break;
            case 'tienganh':
              subjectName = 'Tiếng Anh';
              break;
            case 'khoahoctunhien':
              subjectName = 'Khoa Học Tự Nhiên';
              break;
            default:
              subjectName = subjectCode;
          }

          // Note: This will only update progress if chapters are loaded for this subject
          // For a complete solution, we would need to load chapters for each subject
          _updateProgress(subjectName, grade);
        }
      }
    }
  }

  /// Cập nhật tiến độ hoàn thành cho môn học và khối cụ thể
  void _updateProgress(String subject, int grade) {
    final key = _getStorageKey(subject, grade);
    final progressKey = _getProgressKey(subject, grade);
    final completedLessons = completedLessonsBySubject[key] ?? {};

    // Only update progress if we have chapters for this subject and grade
    if (this.subject == subject && this.grade == grade) {
      int totalLessons = chapters.fold(0, (sum, chapter) => sum + chapter.lessons.length);
      if (totalLessons == 0) {
        _progressBySubject[progressKey] = 0.0;
        _progressBySubject.refresh();
        return;
      }

      int doneLessons = chapters.fold(
        0,
            (sum, chapter) =>
        sum + chapter.lessons.where((lesson) => completedLessons.contains(lesson.title)).length,
      );

      _progressBySubject[progressKey] = doneLessons / totalLessons;
      _progressBySubject.refresh();
    }
  }

  /// Tính tiến độ hoàn thành (%) cho môn học và khối cụ thể
  double getProgress(String subject, int grade) {
    final progressKey = _getProgressKey(subject, grade);
    return _progressBySubject[progressKey] ?? 0.0;
  }
}