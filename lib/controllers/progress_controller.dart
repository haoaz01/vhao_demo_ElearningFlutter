import 'package:get/get.dart' hide Progress;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/streak_utils.dart';
import '../model/progress_model.dart';
import '../repositories/progress_repository.dart';
import '../repositories/streak_repository.dart';

class ProgressController extends GetxController {
  // Repositories
  final ProgressRepository progressRepository = ProgressRepository();
  final StreakRepository streakRepository = StreakRepository();

  // Progress state
  final RxList<Progress> progressList = <Progress>[].obs;
  final RxMap<String, bool> lessonCompletionStatus = <String, bool>{}.obs;
  final RxBool isLoading = false.obs;

  // User state
  final RxBool isLoggedIn = false.obs;
  final RxInt userId = 0.obs;

  // Streak state
  final RxInt currentStreak = 0.obs;
  final RxInt bestStreak = 0.obs;
  final RxInt totalDays = 0.obs;
  final Rxn<DateTime> lastActive = Rxn<DateTime>();

  /// Trigger UI refreshes for streak-related widgets (use `ever(statsVersion, ...)`)
  final RxInt statsVersion = 0.obs;

  /// Mark that streak has been loaded at least once
  final RxBool streakLoaded = false.obs;

  // ===== Local study-days (optional local cache) =====
  static const String _studyDaysKey = 'study_days';

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    return '$y-$m-$da';
  }

  DateTime _parseDay(String s) {
    final parts = s.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    return DateTime(y, m, d);
  }
  // ===== END Local study-days =====


  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    loadStreak(); // ✅ chỉ còn 1 hàm, không lỗi tham số
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userId.value = prefs.getInt('userId') ?? 0;
    isLoggedIn.value = prefs.getBool('isLoggedIn') ?? false;
    // Debug
    // ignore: avoid_print
    print("🔐 ProgressController - userId=${userId.value}, isLoggedIn=${isLoggedIn.value}");
  }

  // Always refresh userId from SharedPreferences (source of truth)
  Future<int> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId') ?? 0;
    userId.value = id;
    return id;
  }

  // ===== Streak API (server-first, local optional) =====
  /// Đồng bộ/lấy streak từ server. Có thể dùng [token] nếu repo hỗ trợ.
  Future<void> loadStreak({String? token}) async {
    try {
      final uid = await _getUserId();
      if (uid <= 0) {
        streakLoaded.value = false;
        return;
      }

      // Server call
      final res = await streakRepository.getStreak(uid /*, token: token*/);
      if (res['statusCode'] == 200 && res['data'] != null) {
        final m = Map<String, dynamic>.from(res['data'] as Map);

        currentStreak.value = (m['streakCount'] ?? m['currentStreak'] ?? 0) as int;
        bestStreak.value    = (m['bestStreak'] ?? 0) as int;
        totalDays.value     = (m['totalDays'] ?? 0) as int;
        lastActive.value    = DateTime.tryParse(m['lastActiveDate']);


        final raw = m['lastActiveDate'];
        final chain = buildStreakChain(
          currentStreak: currentStreak.value,
          lastActiveDate: lastActive.value,
        );
        if (raw is String) {
          lastActive.value = DateTime.tryParse(raw);
        } else {
          lastActive.value = null;
        }

        streakLoaded.value = true;
        statsVersion.value++;
      } else {
        streakLoaded.value = false;
      }

      // Đảm bảo local key tồn tại (không ảnh hưởng server streak)
      await readStudyDays();
    } catch (e) {
      streakLoaded.value = false;
      // ignore: avoid_print
      print('⚠️ loadStreak error: $e');
    }
  }

  /// Chạm streak hôm nay trên server, sau đó refresh lại số liệu.
  Future<void> touchStreakToday() async {
    try {
      final uid = await _getUserId();
      if (uid <= 0) return;

      final res = await streakRepository.touchStreak(uid);
      if (res['statusCode'] == 200) {
        await markStudiedOn();      // <— thêm dòng này
        await loadStreak(); // refresh
      }
    } catch (_) {
      // swallow, UI không cần crash
    }
  }

  // ===== Local study-days helpers (tuỳ chọn) =====
  /// Trả về tập các ngày học (mỗi ngày chuẩn hoá 00:00)
  Future<Set<DateTime>> readStudyDays() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_studyDaysKey) ?? <String>[];
    return list.map(_parseDay).map(_dayKey).toSet();
  }

  /// Ghi nhận đã học vào ngày [date] (mặc định hôm nay) – LOCAL ONLY
  Future<void> markStudiedOn([DateTime? date]) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_studyDaysKey) ?? <String>[];

    final day = _fmt(_dayKey(date ?? DateTime.now()));
    if (!list.contains(day)) {
      list.add(day);
      await prefs.setStringList(_studyDaysKey, list);
      streakLoaded.value = true;
      statsVersion.value++;
      // ignore: avoid_print
      print('🔥 Marked studied on $day');
    }
  }

  /// Ghi đè toàn bộ từ server (nếu cần dùng)
  Future<void> _overwriteStudyDays(Set<DateTime> days) async {
    final prefs = await SharedPreferences.getInstance();
    final list = days.map(_fmt).toList()..sort();
    await prefs.setStringList(_studyDaysKey, list);
    streakLoaded.value = true;
    statsVersion.value++;
  }
  // ===== END Streak API =====

  // ===== Progress APIs =====
  Future<void> completeLesson(int lessonId) async {
    await touchStreakToday(); // ✅ cập nhật streak server khi hoàn thành bài

    try {
      isLoading.value = true;
      final uid = await _getUserId();
      if (uid == 0) throw Exception('User ID not found');

      // ignore: avoid_print
      print("🎯 Completing lesson $lessonId for user $uid");

      await progressRepository.completeLesson(uid, lessonId);

      // Local state update
      lessonCompletionStatus['$uid-$lessonId'] = true;

      // Refresh overall progress
      await fetchProgressByUser();
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error completing lesson: $e");
      Get.snackbar('Lỗi', 'Không thể đánh dấu bài học đã hoàn thành: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uncompleteLesson(int lessonId) async {
    try {
      isLoading.value = true;
      final uid = await _getUserId();
      if (uid == 0) throw Exception('User ID not found');

      // ignore: avoid_print
      print("🎯 Uncompleting lesson $lessonId for user $uid");

      await progressRepository.uncompleteLesson(uid, lessonId);

      lessonCompletionStatus['$uid-$lessonId'] = false;

      await fetchProgressByUser();

      // Không xoá study-day đã ghi trước đó để tránh tụt streak ngoài ý muốn.
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error uncompleting lesson: $e");
      Get.snackbar('Lỗi', 'Không thể hủy đánh dấu hoàn thành: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> isLessonCompleted(int lessonId) async {
    final uid = await _getUserId();
    if (uid == 0) {
      // ignore: avoid_print
      print("⚠️ User ID is 0, cannot check completion");
      return false;
    }

    // Check in-memory first
    final key = '$uid-$lessonId';
    if (lessonCompletionStatus.containsKey(key)) {
      final status = lessonCompletionStatus[key]!;
      // ignore: avoid_print
      print("📚 Lesson $lessonId completion status (memory): $status");
      return status;
    }

    // Fallback to API
    try {
      // ignore: avoid_print
      print("🌐 Checking lesson completion from API...");
      final completed = await progressRepository.checkLessonCompletion(uid, lessonId);
      lessonCompletionStatus[key] = completed;
      // ignore: avoid_print
      print("📚 Lesson $lessonId completion status (API): $completed");
      return completed;
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error checking lesson completion: $e");
      return false;
    }
  }

  Future<void> fetchProgressByUser() async {
    try {
      isLoading.value = true;
      final uid = await _getUserId();
      if (uid == 0) throw Exception('User ID not found');

      final items = await progressRepository.getProgressByUser(uid);
      progressList.assignAll(items);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải tiến trình: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Progress?> getProgressBySubject(int subjectId) async {
    try {
      final uid = await _getUserId();
      if (uid == 0) throw Exception('User ID not found');

      return await progressRepository.getProgressBySubject(uid, subjectId);
    } catch (_) {
      return null;
    }
  }

  Future<List<Progress>> getProgressByGrade(int grade) async {
    try {
      final uid = await _getUserId();
      if (uid == 0) throw Exception('User ID not found');

      return await progressRepository.getProgressByGrade(uid, grade);
    } catch (_) {
      return <Progress>[];
    }
  }

  // Tổng tiến trình trên tất cả các môn
  double get overallProgress {
    if (progressList.isEmpty) return 0.0;
    double totalPercent = 0.0;
    for (final p in progressList) {
      totalPercent += p.progressPercent;
    }
    return totalPercent / progressList.length;
  }
}
