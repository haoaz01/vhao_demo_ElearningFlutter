class StreakState {
  final int current;
  final int longest;
  final int total;
  final DateTime? lastCheckIn;

  StreakState({
    required this.current,
    required this.longest,
    required this.total,
    required this.lastCheckIn,
  });

  factory StreakState.fromJson(Map<String, dynamic> j) => StreakState(
    current: (j['current'] ?? j['currentStreak'] ?? 0) as int,
    longest: (j['longest'] ?? j['bestStreak'] ?? 0) as int,
    total:   (j['total']   ?? j['totalDays']   ?? 0) as int,
    lastCheckIn: j['lastCheckIn'] == null ? null : DateTime.tryParse(j['lastCheckIn'].toString()),
  );

  static StreakState empty() => StreakState(current: 0, longest: 0, total: 0, lastCheckIn: null);
}
