/// Real-time view of an in-progress exercise session, mirrored from the
/// caregiver app to seniors/{id}/live/current.
class LiveSession {
  final bool active;
  final int repCount;
  final DateTime? updatedAt;

  const LiveSession({
    required this.active,
    required this.repCount,
    this.updatedAt,
  });

  factory LiveSession.fromMap(Map<String, dynamic> map) {
    final ms = (map['updatedAt'] as num?)?.toInt();
    return LiveSession(
      active: map['active'] as bool? ?? false,
      repCount: (map['repCount'] as num?)?.toInt() ?? 0,
      updatedAt:
          ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null,
    );
  }

  /// Considered live only if marked active and updated recently — guards
  /// against a stale doc that was never cleared (e.g. caregiver app killed).
  bool get isLive {
    if (!active) return false;
    final u = updatedAt;
    if (u == null) return true;
    return DateTime.now().difference(u) < const Duration(minutes: 5);
  }
}
