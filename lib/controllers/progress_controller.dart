import 'dart:convert';

import 'package:get/get.dart' hide Progress;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../model/progress_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/progress_repository.dart';
import '../repositories/streak_repository.dart';
import '../screens/streak_screen.dart';
import '../repositories/quiz_repository.dart';
import '../model/quiz_progress_model.dart';
import '../model/quiz_daily_stat_model.dart';
import 'auth_controller.dart';

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

  // Quiz progress
  final QuizRepository quizRepository = QuizRepository();

  final Rxn<QuizProgressModel> quizProgress = Rxn<QuizProgressModel>();
  final RxList<QuizDailyStat> quizDaily = <QuizDailyStat>[].obs;
  final RxBool isQuizLoading = false.obs;

  /// Trigger UI refreshes for streak-related widgets (use `ever(statsVersion, ...)`)
  final RxInt statsVersion = 0.obs;

  /// Mark that streak has been loaded at least once
  final RxBool streakLoaded = false.obs;

  // ===== Local study-days (optional local cache) =====
  static const String _studyDaysKey = 'study_days';

  late final AuthController auth;

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
    auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());
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
    print(
        "🔐 ProgressController - userId=${userId.value}, isLoggedIn=${isLoggedIn
            .value}");
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

      final res = await streakRepository.getStreak(uid);
      if (res['statusCode'] == 200 && res['data'] != null) {
        final m = Map<String, dynamic>.from(res['data'] as Map);

        currentStreak.value = (m['currentStreak'] ?? 0) as int;
        bestStreak.value = (m['bestStreak'] ?? 0) as int;
        totalDays.value = (m['totalDays'] ?? 0) as int;
        lastActive.value = DateTime.tryParse(m['lastActiveDate'] ?? '');

        streakLoaded.value = true;
        statsVersion.value++; // ❗️để UI nghe thay đổi
      } else {
        streakLoaded.value = false;
      }

      await readStudyDays(); // optional local cache
    } catch (e) {
      streakLoaded.value = false;
      print('⚠️ loadStreak error: $e');
    }
  }

  /// Chạm streak hôm nay trên server, sau đó refresh lại số liệu.
  // Future<void> touchStreakToday() async {
  //   try {
  //     final uid = await _getUserId();
  //     if (uid <= 0) return;
  //
  //     final res = await streakRepository.touchStreak(uid);
  //     print('touch status=${res['statusCode']}, body=${res['data']}');
  //     if (res['statusCode'] == 200) {
  //       await markStudiedOn();      // <— thêm dòng này
  //       await loadStreak(); // refresh
  //     }
  //   } catch (_) {
  //     // swallow, UI không cần crash
  //   }
  // }

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
    final list = days.map(_fmt).toList()
      ..sort();
    await prefs.setStringList(_studyDaysKey, list);
    streakLoaded.value = true;
    statsVersion.value++;
  }

  // ===== END Streak API =====

  // ===== Progress APIs =====
  Future<void> completeLesson(int lessonId) async {
    // await touchStreakToday(); // ✅ cập nhật streak server khi hoàn thành bài

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
      final completed = await progressRepository.checkLessonCompletion(
          uid, lessonId);
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

  Future<void> markOnline() async {
    final uid = await _getUserId();
    if (uid <= 0) return;
    final res = await streakRepository.online(
        uid); // POST /api/streak/{userId}/online
    // tuỳ chọn load lại:
    if (res['statusCode'] == 200) {
      await loadStreak();
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

  Future<void> loadQuizStats({int days = 7}) async {
    try {
      isQuizLoading.value = true;
      final uid = await _getUserId();
      if (uid <= 0) { quizDaily.clear(); return; }

      // gọi repo (đã trỏ đúng /api/progress/accuracy/daily)
      final list = await progressRepository.getQuizDailyHistory(userId: uid, days: days);

      final fetched = list.map((e) => QuizDailyStat(
        day: e['day'] as DateTime,
        correctSum: e['correct'] as int,
        totalSum: e['total'] as int,
        percentAccuracy: e['percent'] as double,
      )).toList();

      final now = DateTime.now();
      final from = now.subtract(Duration(days: days - 1));
      final filled = _densifyDays(src: fetched, fromDate: from, toDate: now);

      // gán ra cho chart
      quizDaily.assignAll(filled);
    } catch (e) {
      print('💥 loadQuizStats error: $e');
      quizDaily.clear();
    } finally {
      isQuizLoading.value = false;
    }
  }

  List<QuizDailyStat> _densifyDays({
    required List<QuizDailyStat> src,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    // key theo "ngày" (00:00)
    DateTime dayKey(DateTime d) => DateTime(d.year, d.month, d.day);
    final map = {for (final p in src) dayKey(p.day): p};

    final out = <QuizDailyStat>[];
    for (var d = dayKey(fromDate); !d.isAfter(dayKey(toDate)); d = d.add(const Duration(days: 1))) {
      out.add(
        map[d] ??
            QuizDailyStat(
              day: d,
              correctSum: 0,
              totalSum: 0,
              percentAccuracy: 0.0,
            ),
      );
    }
    return out;
  }
}


