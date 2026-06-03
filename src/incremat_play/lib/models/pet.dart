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
  // Family display name shown in discovery grid and subtitles.
  String get label => switch (this) {
        PetSpecies.otter => 'Teh Tarik Otter',
        PetSpecies.fox => 'Sun-Flare Fox',
        PetSpecies.tortoise => 'Earth-Tortoise',
        PetSpecies.koi => 'Zen Koi',
      };

  // Full title from the Incremon Lexicon.
  String get familyTitle => switch (this) {
        PetSpecies.tortoise => 'Bonsai Earth-Tortoise: Guardian of Stability',
        PetSpecies.fox => 'Sun-Flare Fox: Spirit of Radiance',
        PetSpecies.otter => 'Teh Tarik Otter: Weaver of Joy',
        PetSpecies.koi => 'Zen Koi: Ascendant of Harmony',
      };

  // Stage-specific Incremon name (shown as the pet's name in-game).
  String stageName(PetStage stage) => switch (this) {
        PetSpecies.tortoise => switch (stage) {
            PetStage.egg || PetStage.baby => 'Pebbleling',
            PetStage.young => 'Mossheart',
            PetStage.adult => 'Ancient Isle',
          },
        PetSpecies.fox => switch (stage) {
            PetStage.egg || PetStage.baby => 'Spark-cub',
            PetStage.young => 'Leafdancer',
            PetStage.adult => 'Nine-Tailed Kitsune',
          },
        PetSpecies.otter => switch (stage) {
            PetStage.egg || PetStage.baby => 'Tea-bubble',
            PetStage.young => 'Froth-Weaver',
            PetStage.adult => 'Froth-Dragon Otter',
          },
        PetSpecies.koi => switch (stage) {
            PetStage.egg || PetStage.baby => 'Fry',
            PetStage.young => 'Pond Dweller',
            PetStage.adult => 'Dragon Koi',
          },
      };

  // Short flavour description for each stage.
  String stageTagline(PetStage stage) => switch (this) {
        PetSpecies.tortoise => switch (stage) {
            PetStage.egg || PetStage.baby =>
              'A moss-kissed pebble shell, brimming with quiet potential.',
            PetStage.young =>
              'A resilient sprout blooms from its shell — calm, steady strength.',
            PetStage.adult =>
              'A living mountain landscape crowned by an ancient glowing Bonsai.',
          },
        PetSpecies.fox => switch (stage) {
            PetStage.egg || PetStage.baby =>
              'Born from the first rays of dawn, shimmering with golden light.',
            PetStage.young =>
              'Golden autumn leaves swirl in the wake of every graceful step.',
            PetStage.adult =>
              'Nine solar flare tails — a celestial marvel of pure radiance.',
          },
        PetSpecies.otter => switch (stage) {
            PetStage.egg || PetStage.baby =>
              'A tiny otter swirling with the warmth of frothy milk tea.',
            PetStage.young =>
              'Weaves streams of frothy tea in joyful, harmonious patterns.',
            PetStage.adult =>
              'Commands cascades of creamy foam — master of joyful living.',
          },
        PetSpecies.koi => switch (stage) {
            PetStage.egg || PetStage.baby =>
              'Soft hopeful scales, full of boundless unrealised potential.',
            PetStage.young =>
              'Glides with calm purpose in a stone basin among lily pads.',
            PetStage.adult =>
              'Ascends a waterfall of light with shimmering golden scales.',
          },
      };

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

// The kind of milestone recorded in the history timeline.
enum HistoryEventType { exp, eggReceived, hatched }

class ExpEvent {
  final String id;
  final DateTime date;
  final String petId;
  final String? species;
  final PetStage stageBefore;
  final PetStage stageAfter;
  final int amount;
  final bool evolved;
  final HistoryEventType type;

  const ExpEvent({
    required this.id,
    required this.date,
    required this.petId,
    required this.stageBefore,
    required this.stageAfter,
    required this.amount,
    required this.evolved,
    this.species,
    this.type = HistoryEventType.exp,
  });

  factory ExpEvent.fromMap(String id, Map<String, dynamic> map) {
    final beforeIdx = (map['stageBefore'] as int? ?? 0)
        .clamp(0, PetStage.values.length - 1);
    final afterIdx = (map['stageAfter'] as int? ?? 0)
        .clamp(0, PetStage.values.length - 1);
    final typeName = map['type'] as String?;
    final type = HistoryEventType.values
            .where((t) => t.name == typeName)
            .firstOrNull ??
        HistoryEventType.exp;
    return ExpEvent(
      id: id,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      petId: map['petId'] as String? ?? '',
      species: map['species'] as String?,
      stageBefore: PetStage.values[beforeIdx],
      stageAfter: PetStage.values[afterIdx],
      amount: map['amount'] as int? ?? 1,
      evolved: map['evolved'] as bool? ?? false,
      type: type,
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'petId': petId,
        'species': species,
        'stageBefore': stageBefore.index,
        'stageAfter': stageAfter.index,
        'amount': amount,
        'evolved': evolved,
        'type': type.name,
      };
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
