List<DateTime> buildStreakChain({
  required int currentStreak,
  required DateTime? lastActiveDate,
  DateTime? now,
}) {
  if (currentStreak <= 0 || lastActiveDate == null) return [];
  final today = DateTime.now();
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  final dToday = day(now ?? today);
  final anchor = day(lastActiveDate);

  // nếu anchor < yesterday => đã đứt
  if (anchor.isBefore(dToday.subtract(const Duration(days: 1)))) {
    return [];
  }

  // build list từ (anchor - (len-1)) đến anchor
  final len = currentStreak;
  return List.generate(len, (i) {
    final offset = len - 1 - i;
    final d = anchor.subtract(Duration(days: offset));
    return day(d);
  });
}
