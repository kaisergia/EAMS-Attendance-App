class Event {
  final String id;
  final String officeId;
  final String name;
  final String description;
  final DateTime eventDate;
  final bool isActive;
  final String? requirementId;
  final String? requirementName;

  Event({
    required this.id,
    required this.officeId,
    required this.name,
    required this.description,
    required this.eventDate,
    required this.isActive,
    this.requirementId,
    this.requirementName,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    final req = map['requirement'];
    return Event(
      id: map['id'] as String,
      officeId: map['office_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      eventDate: DateTime.parse(map['event_date'] as String),
      isActive: map['is_active'] as bool? ?? true,
      requirementId: map['requirement_id'] as String?,
      requirementName: req is Map ? req['name'] as String? : null,
    );
  }
}
