import 'package:get/get.dart' hide Progress;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/progress_model.dart';
import '../repositories/progress_repository.dart';

class ProgressController extends GetxController {
  final ProgressRepository progressRepository = ProgressRepository();
  final RxList<Progress> progressList = <Progress>[].obs;
  final RxMap<String, bool> lessonCompletionStatus = <String, bool>{}.obs;
  final RxBool isLoading = false.obs;

  // THÊM CÁC GETTER MỚI
  final RxBool isLoggedIn = false.obs;
  final RxInt userId = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData(); // THÊM: Tải dữ liệu user khi khởi tạo
  }

  // THÊM PHƯƠNG THỨC MỚI: Tải dữ liệu user từ SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userId.value = prefs.getInt('userId') ?? 0;
    isLoggedIn.value = prefs.getBool('isLoggedIn') ?? false;

    print("🔐 ProgressController - UserId: ${userId.value}, IsLoggedIn: ${isLoggedIn.value}");
  }

  // Lấy userId từ SharedPreferences (GIỮ NGUYÊN)
  Future<int> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId') ?? 0;
    userId.value = id; // CẬP NHẬT GIÁ TRỊ
    return id;
  }

  // Đánh dấu bài học đã hoàn thành
  Future<void> completeLesson(int lessonId) async {
    try {
      isLoading.value = true;
      final userId = await _getUserId();
      if (userId == 0) throw Exception('User ID not found');

      // THÊM DEBUG LOG
      print("🎯 Completing lesson $lessonId for user $userId");

      await progressRepository.completeLesson(userId, lessonId);
      // Cập nhật trạng thái cục bộ
      lessonCompletionStatus['$userId-$lessonId'] = true;
      // Cập nhật tiến trình
      await fetchProgressByUser();
    } catch (e) {
      print("❌ Error completing lesson: $e");
      Get.snackbar('Lỗi', 'Không thể đánh dấu bài học đã hoàn thành: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Hủy đánh dấu hoàn thành
  Future<void> uncompleteLesson(int lessonId) async {
    try {
      isLoading.value = true;
      final userId = await _getUserId();
      if (userId == 0) throw Exception('User ID not found');

      print("🎯 Uncompleting lesson $lessonId for user $userId");

      await progressRepository.uncompleteLesson(userId, lessonId);
      // Cập nhật trạng thái cục bộ
      lessonCompletionStatus['$userId-$lessonId'] = false;
      // Cập nhật tiến trình
      await fetchProgressByUser();
    } catch (e) {
      print("❌ Error uncompleting lesson: $e");
      Get.snackbar('Lỗi', 'Không thể hủy đánh dấu hoàn thành: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Kiểm tra trạng thái hoàn thành của một bài học
  Future<bool> isLessonCompleted(int lessonId) async {
    final userId = await _getUserId();
    if (userId == 0) {
      print("⚠️ User ID is 0, cannot check completion");
      return false;
    }

    // Kiểm tra trong bộ nhớ trước
    if (lessonCompletionStatus.containsKey('$userId-$lessonId')) {
      final status = lessonCompletionStatus['$userId-$lessonId']!;
      print("📚 Lesson $lessonId completion status from memory: $status");
      return status;
    }

    // Nếu chưa có, gọi API để kiểm tra
    try {
      print("🌐 Checking lesson completion from API...");
      final completed = await progressRepository.checkLessonCompletion(userId, lessonId);
      lessonCompletionStatus['$userId-$lessonId'] = completed;
      print("📚 Lesson $lessonId completion status from API: $completed");
      return completed;
    } catch (e) {
      print("❌ Error checking lesson completion: $e");
      // Nếu có lỗi, trả về false
      return false;
    }
  }

  // Lấy tất cả tiến trình của user
  Future<void> fetchProgressByUser() async {
    try {
      isLoading.value = true;
      final userId = await _getUserId();
      if (userId == 0) throw Exception('User ID not found');

      final List<Progress> progress = await progressRepository.getProgressByUser(userId);
      progressList.assignAll(progress); // SỬA: assignAll nhận Iterable<Progress>
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải tiến trình: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Lấy tiến trình theo môn học
  Future<Progress?> getProgressBySubject(int subjectId) async {
    try {
      final userId = await _getUserId();
      if (userId == 0) throw Exception('User ID not found');

      return await progressRepository.getProgressBySubject(userId, subjectId);
    } catch (e) {
      return null;
    }
  }

  // Lấy tiến trình theo khối lớp
  Future<List<Progress>> getProgressByGrade(int grade) async {
    try {
      final userId = await _getUserId();
      if (userId == 0) throw Exception('User ID not found');

      return await progressRepository.getProgressByGrade(userId, grade);
    } catch (e) {
      return []; // SỬA: Trả về List<Progress> rỗng
    }
  }

// Tính tổng tiến trình trên tất cả các môn
  double get overallProgress {
    if (progressList.isEmpty) return 0.0;

    double totalPercent = 0.0;
    int count = 0;

    for (var progress in progressList) {
      totalPercent += progress.progressPercent;
      count++;
    }

    return count > 0 ? totalPercent / count : 0.0;
  }

}