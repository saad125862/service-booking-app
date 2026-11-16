class TimeSlot {
  const TimeSlot({required this.start, required this.end, required this.label, required this.available});

  final DateTime start;
  final DateTime end;

  /// e.g. "10:00 AM" in the business time zone.
  final String label;
  final bool available;

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    label: json['label'] as String,
    available: json['available'] as bool,
  );

  @override
  bool operator ==(Object other) => other is TimeSlot && other.start == start;

  @override
  int get hashCode => start.hashCode;
}

class Availability {
  const Availability({required this.date, required this.timeZone, required this.slots});

  final String date;
  final String timeZone;
  final List<TimeSlot> slots;

  bool get hasAvailableSlot => slots.any((s) => s.available);

  factory Availability.fromJson(Map<String, dynamic> json) => Availability(
    date: json['date'] as String,
    timeZone: json['timeZone'] as String,
    slots: [for (final s in json['slots'] as List) TimeSlot.fromJson(s as Map<String, dynamic>)],
  );
}
