class DashboardData {
  final Map<String, dynamic> databaseOverview;
  final List<dynamic> slowQueries;
  final List<dynamic> activeSessions;
  final Map<String, dynamic> healthOverview;
  final List<dynamic> tableStats;
  final Map<String, dynamic> queryStats;
  final DateTime lastUpdated;

  DashboardData({
    required this.databaseOverview,
    required this.slowQueries,
    required this.activeSessions,
    required this.healthOverview,
    required this.tableStats,
    required this.queryStats,
    required this.lastUpdated,
  });
}