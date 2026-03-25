class Organization {
  final String id;
  final String name;
  final String code;
  final String sourceType; // 'office', 'department', 'club'
  final String? headId;

  Organization({
    required this.id,
    required this.name,
    required this.code,
    required this.sourceType,
    this.headId,
  });

  factory Organization.fromMap(Map<String, dynamic> map, String sourceType) {
    return Organization(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      sourceType: sourceType,
      headId: (sourceType == 'club'
          ? map['adviser_id'] as String?
          : map['head_id'] as String?),
    );
  }
}
