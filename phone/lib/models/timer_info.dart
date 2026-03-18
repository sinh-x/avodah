/// A PA systemd timer entry from GET /api/timers.
class TimerInfo {
  final String unit;
  final String team;
  final String nextIn;

  const TimerInfo({
    required this.unit,
    required this.team,
    required this.nextIn,
  });

  factory TimerInfo.fromJson(Map<String, dynamic> json) {
    return TimerInfo(
      unit: json['unit'] as String? ?? '',
      team: json['team'] as String? ?? '',
      nextIn: json['next_in'] as String? ?? '',
    );
  }
}
