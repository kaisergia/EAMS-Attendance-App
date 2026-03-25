class Event {
  final String id;
  final String sourceType;
  final String sourceId;
  final String name;
  final String description;
  final DateTime eventDate;
  final bool isActive;
  final String? requirementId;
  final String? requirementName;
  final bool requireLogout;

  Event({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.name,
    required this.description,
    required this.eventDate,
    required this.isActive,
    this.requirementId,
    this.requirementName,
    this.requireLogout = false,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    final req = map['requirement'];
    return Event(
      id: map['id'] as String,
      sourceType: map['source_type'] as String,
      sourceId: map['source_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      eventDate: DateTime.parse(map['event_date'] as String),
      isActive: map['is_active'] as bool? ?? true,
      requirementId: map['requirement_id'] as String?,
      requirementName: req is Map ? req['name'] as String? : null,
      requireLogout: map['require_logout'] as bool? ?? false,
    );
  }
}
