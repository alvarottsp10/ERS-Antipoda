class CommercialOption {
  const CommercialOption({
    required this.userId,
    required this.fullName,
  });

  final String userId;
  final String fullName;

  factory CommercialOption.fromMap(Map<String, dynamic> map) {
    return CommercialOption(
      userId: (map['user_id'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
    );
  }
}

class WorkflowPhaseOption {
  const WorkflowPhaseOption({
    required this.id,
    required this.code,
    required this.name,
  });

  final int id;
  final String code;
  final String name;

  factory WorkflowPhaseOption.fromMap(Map<String, dynamic> map) {
    return WorkflowPhaseOption(
      id: ((map['id'] as num?) ?? 0).toInt(),
      code: (map['code'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
    );
  }
}
