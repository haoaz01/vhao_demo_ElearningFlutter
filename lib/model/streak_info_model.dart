class StreakInfo {
  final bool success;
  final int currentStreak;
  final int todayMinutes;
  final int minStudyMinutes;
  final int remainingMinutes;

  StreakInfo({
    required this.success,
    required this.currentStreak,
    required this.todayMinutes,
    required this.minStudyMinutes,
    required this.remainingMinutes,
  });

  factory StreakInfo.fromJson(Map<String, dynamic> json) {
    return StreakInfo(
      success: json['success'] ?? false,
      currentStreak: json['currentStreak'] ?? 0,
      todayMinutes: json['todayMinutes'] ?? 0,
      minStudyMinutes: json['minStudyMinutes'] ?? 15,
      remainingMinutes: json['remainingMinutes'] ?? 0,
    );
  }

  // Helper method để kiểm tra đã đạt mục tiêu chưa
  bool get isTargetAchieved => todayMinutes >= minStudyMinutes;

  // Helper method để lấy phần trăm tiến trình
  double get progressPercent => todayMinutes / minStudyMinutes;
}