class ActivityData {
  final List<dynamic> activeSessions;
  final List<dynamic> idleSessions;
  final List<dynamic> locks;
  final List<dynamic> blockedQueries;
  final DateTime lastUpdated;

  ActivityData({
    required this.activeSessions,
    required this.idleSessions,
    required this.locks,
    required this.blockedQueries,
    required this.lastUpdated,
  });
}