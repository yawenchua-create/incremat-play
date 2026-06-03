/// A shared Live Duet lobby, stored at duets/{code}. Holds only the two
/// participants' senior IDs / names / goals — never any login credential — so
/// the code is safe to share just to pair up.
class DuetSession {
  final String code;
  final String hostId;
  final String hostName;
  final int hostGoal;
  final String? guestId;
  final String? guestName;
  final int? guestGoal;

  const DuetSession({
    required this.code,
    required this.hostId,
    required this.hostName,
    required this.hostGoal,
    this.guestId,
    this.guestName,
    this.guestGoal,
  });

  bool get isFull => guestId != null;

  factory DuetSession.fromMap(String code, Map<String, dynamic> m) =>
      DuetSession(
        code: code,
        hostId: m['hostId'] as String? ?? '',
        hostName: m['hostName'] as String? ?? 'Host',
        hostGoal: (m['hostGoal'] as num?)?.toInt() ?? 25,
        guestId: m['guestId'] as String?,
        guestName: m['guestName'] as String?,
        guestGoal: (m['guestGoal'] as num?)?.toInt(),
      );
}
