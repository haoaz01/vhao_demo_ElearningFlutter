// helpers/study_session_store.dart (ví dụ)
import 'package:shared_preferences/shared_preferences.dart';

class SessionSnapshot {
  final DateTime sessionStartTime;
  final int bufferedSeconds;
  final int sessionAccruedMinutes; // NEW
  SessionSnapshot({
    required this.sessionStartTime,
    required this.bufferedSeconds,
    required this.sessionAccruedMinutes,
  });
}

class StudySessionStore {
  static const _kStart = 'ss_start';
  static const _kBuf = 'ss_buf';
  static const _kAcc = 'ss_acc'; // NEW

  Future<void> save({
    required DateTime? sessionStartTime,
    required int bufferedSeconds,
    required int sessionAccruedMinutes, // NEW
  }) async {
    final sp = await SharedPreferences.getInstance();
    if (sessionStartTime != null) {
      await sp.setString(_kStart, sessionStartTime.toIso8601String());
    }
    await sp.setInt(_kBuf, bufferedSeconds);
    await sp.setInt(_kAcc, sessionAccruedMinutes); // NEW
  }

  Future<SessionSnapshot?> loadIfSameDay() async {
    final sp = await SharedPreferences.getInstance();
    final startStr = sp.getString(_kStart);
    if (startStr == null) return null;
    final start = DateTime.tryParse(startStr);
    if (start == null) return null;

    final now = DateTime.now();
    final sameDay = start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
    if (!sameDay) return null;

    return SessionSnapshot(
      sessionStartTime: start,
      bufferedSeconds: sp.getInt(_kBuf) ?? 0,
      sessionAccruedMinutes: sp.getInt(_kAcc) ?? 0, // NEW
    );
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kStart);
    await sp.remove(_kBuf);
    await sp.remove(_kAcc); // NEW
  }
}
