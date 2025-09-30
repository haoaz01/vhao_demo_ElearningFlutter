class CalendarDayDTO {
  final DateTime date;
  final bool studied;
  final int minutesStudied;
  final bool isInCurrentStreak;

  CalendarDayDTO({
    required this.date,
    required this.studied,
    required this.minutesStudied,
    required this.isInCurrentStreak,
  });

  factory CalendarDayDTO.fromJson(Map<String, dynamic> json) {
    return CalendarDayDTO(
      date: DateTime.parse(json['date'].toString()),
      studied: json['studied'] == true,
      minutesStudied: (json['minutesStudied'] ?? 0) as int,
      isInCurrentStreak: json['isInCurrentStreak'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    // Backend dùng LocalDate => chỉ cần yyyy-MM-dd
    final String ymd = date.toIso8601String().split('T')[0];
    return {
      'date': ymd,
      'studied': studied,
      'minutesStudied': minutesStudied,
      'isInCurrentStreak': isInCurrentStreak,
    };
  }
}
