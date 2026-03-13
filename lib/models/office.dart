class Office {
  final String id;
  final String name;
  final String code;
  final String? headId;

  Office({
    required this.id,
    required this.name,
    required this.code,
    this.headId,
  });

  factory Office.fromMap(Map<String, dynamic> map) {
    return Office(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      headId: map['head_id'] as String?,
    );
  }
}
