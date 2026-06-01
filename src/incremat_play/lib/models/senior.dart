class Senior {
  final String id;
  final String name;
  final int age;
  final int dailyRepGoal;
  final int consistencyThreshold;
  final String? joinCode;

  const Senior({
    required this.id,
    required this.name,
    required this.age,
    required this.dailyRepGoal,
    required this.consistencyThreshold,
    this.joinCode,
  });

  factory Senior.fromMap(String id, Map<String, dynamic> map) => Senior(
        id: id,
        name: map['name'] as String? ?? '',
        age: map['age'] as int? ?? 0,
        dailyRepGoal: map['dailyRepGoal'] as int? ?? 25,
        consistencyThreshold: map['consistencyThreshold'] as int? ?? 4,
        joinCode: map['joinCode'] as String?,
      );
}
