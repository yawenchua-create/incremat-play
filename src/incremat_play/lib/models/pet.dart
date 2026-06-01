enum PetStage { egg, baby, young, adult }

enum PetSpecies { otter, fox, tortoise, koi }

extension PetStageLabel on PetStage {
  String get label {
    switch (this) {
      case PetStage.egg:
        return 'Egg';
      case PetStage.baby:
        return 'Baby';
      case PetStage.young:
        return 'Young';
      case PetStage.adult:
        return 'Adult';
    }
  }

  int get expToNext {
    switch (this) {
      case PetStage.egg:
        return 3;
      case PetStage.baby:
        return 5;
      case PetStage.young:
        return 10;
      case PetStage.adult:
        return 0;
    }
  }
}

extension PetSpeciesInfo on PetSpecies {
  String get label {
    switch (this) {
      case PetSpecies.otter:
        return 'Otter';
      case PetSpecies.fox:
        return 'Fox';
      case PetSpecies.tortoise:
        return 'Tortoise';
      case PetSpecies.koi:
        return 'Koi';
    }
  }

  String imagePath(PetStage stage) {
    final stageName = (stage == PetStage.egg) ? 'baby' : stage.name;
    return 'assets/pets/${name}_$stageName.png';
  }
}

class Pet {
  final String id;
  final String seniorId;
  final PetStage stage;
  final PetSpecies? species;
  final int exp;
  final DateTime awardedAt;
  final bool isHatched;

  const Pet({
    required this.id,
    required this.seniorId,
    required this.stage,
    required this.exp,
    required this.awardedAt,
    this.species,
    this.isHatched = false,
  });

  factory Pet.fromMap(String id, Map<String, dynamic> map) {
    final stageIndex = map['stage'] as int? ?? 0;
    final speciesName = map['species'] as String?;
    // Legacy fallback: old records stored speciesIndex as int
    final speciesIndex = map['speciesIndex'] as int?;
    PetSpecies? species;
    if (speciesName != null) {
      species = PetSpecies.values.where((s) => s.name == speciesName).firstOrNull;
    } else if (speciesIndex != null) {
      final clamped = speciesIndex.clamp(0, PetSpecies.values.length - 1);
      species = PetSpecies.values[clamped];
    }
    return Pet(
      id: id,
      seniorId: map['seniorId'] as String? ?? '',
      stage: PetStage.values[stageIndex.clamp(0, PetStage.values.length - 1)],
      species: species,
      exp: map['exp'] as int? ?? 0,
      awardedAt: map['awardedAt'] != null
          ? DateTime.tryParse(map['awardedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isHatched: map['isHatched'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'seniorId': seniorId,
        'stage': stage.index,
        'species': species?.name,
        'exp': exp,
        'awardedAt': awardedAt.toIso8601String(),
        'isHatched': isHatched,
      };

  Pet copyWith({
    PetStage? stage,
    PetSpecies? species,
    int? exp,
    bool? isHatched,
  }) =>
      Pet(
        id: id,
        seniorId: seniorId,
        stage: stage ?? this.stage,
        species: species ?? this.species,
        exp: exp ?? this.exp,
        awardedAt: awardedAt,
        isHatched: isHatched ?? this.isHatched,
      );
}

class ExerciseSession {
  final String id;
  final DateTime date;
  final int repCount;
  final double avgRepTimeSeconds;

  const ExerciseSession({
    required this.id,
    required this.date,
    required this.repCount,
    required this.avgRepTimeSeconds,
  });

  factory ExerciseSession.fromMap(String id, Map<String, dynamic> map) =>
      ExerciseSession(
        id: id,
        // Caregiver app stores timestamp as millisecondsSinceEpoch (int).
        date: DateTime.fromMillisecondsSinceEpoch(
            (map['timestamp'] as num?)?.toInt() ?? 0),
        repCount: (map['repCount'] as num?)?.toInt() ?? 0,
        avgRepTimeSeconds:
            (map['avgRepTimeSeconds'] as num?)?.toDouble() ?? 0.0,
      );
}
