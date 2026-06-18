/// The Play app's view of a senior. It's a TRIMMED copy of the caregiver app's
/// Senior — the senior app only reads what it needs (name, age, goal) and has no
/// toMap/copyWith because it never WRITES the senior document; the caregiver app
/// owns that. Both apps read the same `seniors/{id}` Firestore document.
class Senior {
  final String id;
  final String name;
  final int age;
  final int dailyRepGoal;            // the daily target the pet's EXP is paced to
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
