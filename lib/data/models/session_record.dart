class SessionRecord {
  final int id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final int blockedCount;

  const SessionRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.blockedCount,
  });

  factory SessionRecord.fromMap(Map<String, dynamic> map) => SessionRecord(
        id: map['id'] as int,
        startTime:
            DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int),
        endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime'] as int),
        durationMinutes: map['durationMinutes'] as int,
        blockedCount: map['blockedCount'] as int,
      );
}
