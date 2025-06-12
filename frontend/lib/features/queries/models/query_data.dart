class QueryData {
  final List<dynamic> slowQueries;
  final Map<String, dynamic> queryStats;
  final List<dynamic> queryTypes;
  final DateTime lastUpdated;

  QueryData({
    required this.slowQueries,
    required this.queryStats,
    required this.queryTypes,
    required this.lastUpdated,
  });
}