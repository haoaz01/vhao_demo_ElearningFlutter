// lib/controllers/streak_controller.dart  (rút gọn phần liên quan)
import 'package:get/get.dart';
import '../repositories/streak_repository.dart';
import 'auth_controller.dart';

class StreakController extends GetxController {
  final streakLoaded = false.obs;

  // các field UI đang dùng trong Dashboard/StreakScreen
  final currentStreak = 0.obs;
  final bestStreak    = 0.obs;
  final totalDays     = 0.obs;
  final lastActive    = Rxn<DateTime>();

  int get _uid => Get.find<AuthController>().userId.value;

  Future<void> fetchStreak() async {
    try {
      final s = await StreakRepository.getStreak(_uid);
      currentStreak.value = s.current;
      bestStreak.value    = s.best;
      totalDays.value     = s.total;
      lastActive.value    = s.lastCheckIn;
      streakLoaded.value  = true;
    } catch (_) {
      streakLoaded.value = true; // vẫn unlock UI, show 0
      currentStreak.value = bestStreak.value = totalDays.value = 0;
      lastActive.value = null;
    }
  }

  Future<void> loadStreak() async {
    final uid = Get.find<AuthController>().userId.value;
    final s = await StreakRepository.getStreak(uid);
    currentStreak.value = s.current;
    bestStreak.value = s.best;
    totalDays.value = s.total;
    lastActive.value = s.lastCheckIn;
    streakLoaded.value = true;
  }
  Future<void> checkInToday() async {
    try {
      await StreakRepository.checkInToday(_uid);
      await fetchStreak();
    } catch (_) {/* im lặng để tránh crash */}
  }

  Future<void> touch() async {
    final uid = Get.find<AuthController>().userId.value;
    await StreakRepository.checkInToday(uid); // hoặc .touch(uid)
    await loadStreak();
  }
}
