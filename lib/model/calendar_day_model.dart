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
      // Sửa: backend trả về 'inCurrentStreak' thay vì 'isInCurrentStreak'
      isInCurrentStreak: json['inCurrentStreak'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'studied': studied,
      'minutesStudied': minutesStudied,
      'inCurrentStreak': isInCurrentStreak, // Sửa để khớp backend
    };
  }
}