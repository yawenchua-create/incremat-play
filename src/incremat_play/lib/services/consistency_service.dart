import '../models/pet.dart';
import '../models/senior.dart';

/// The RULES of the reward system, as pure static functions (no state, easy to
/// test). It defines what an "ISO week" is and decides when a senior has earned
/// an egg — i.e. met their daily goal on enough days this week and not already
/// been awarded one for this week. GameService calls these to make decisions.
class ConsistencyService {
  /// Returns the ISO week string for a given date, e.g. "2025-W22".
  /// (ISO weeks run Mon–Sun and are numbered by the week's Thursday — that's the
  /// fiddly date maths below; the result is a stable per-week key like "2025-W22".)
  static String isoWeek(DateTime date) {
    final thursday = date.subtract(Duration(days: date.weekday - 1))
        .add(const Duration(days: 3));
    final year = thursday.year;
    final firstThursday = DateTime(year, 1, 1)
        .add(Duration(days: (4 - DateTime(year, 1, 1).weekday + 7) % 7));
    final weekNum =
        ((thursday.difference(firstThursday).inDays) / 7).floor() + 1;
    return '$year-W${weekNum.toString().padLeft(2, '0')}';
  }

  /// Returns midnight on the Monday of the ISO week that contains [date].
  static DateTime weekStart(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Checks whether an egg should be awarded this week.
  ///
  /// Returns true if:
  /// - The daily goal was completed on [completionDate]
  /// - The threshold has been met (distinct goal-completion days this week >= threshold)
  /// - No egg has been awarded in [lastEggAwardedWeek] matching this week
  static bool shouldAwardEgg({
    required DateTime completionDate,
    required List<ExerciseSession> sessionsThisWeek,
    required Senior senior,
    required String? lastEggAwardedWeek,
  }) {
    final thisWeek = isoWeek(completionDate);
    if (lastEggAwardedWeek == thisWeek) return false;

    final goalDays = _goalCompletionDays(sessionsThisWeek, senior.dailyRepGoal);
    return goalDays >= senior.consistencyThreshold;
  }

  static int _goalCompletionDays(
      List<ExerciseSession> sessions, int dailyGoal) {
    final Map<String, int> repsByDay = {};
    for (final s in sessions) {
      final key = _dayKey(s.date);
      repsByDay[key] = (repsByDay[key] ?? 0) + s.repCount;
    }
    return repsByDay.values.where((reps) => reps >= dailyGoal).length;
  }

  static String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Public day key, e.g. "2026-06-03". Used to dedupe once-per-day awards.
  static String dayKey(DateTime dt) => _dayKey(dt);

  /// True if the cumulative reps on [date]'s calendar day reach [dailyGoal].
  static bool goalMetOn(
      List<ExerciseSession> sessions, DateTime date, int dailyGoal) {
    final key = _dayKey(date);
    final reps = sessions
        .where((s) => _dayKey(s.date) == key)
        .fold<int>(0, (sum, s) => sum + s.repCount);
    return reps >= dailyGoal;
  }

  /// Counts how many distinct days this week the daily goal was completed.
  static int goalCompletionDaysThisWeek(
      List<ExerciseSession> sessions, int dailyGoal) =>
      _goalCompletionDays(sessions, dailyGoal);
}
