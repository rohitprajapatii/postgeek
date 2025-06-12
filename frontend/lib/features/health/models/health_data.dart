class HealthData {
  final Map<String, dynamic> healthOverview;
  final List<dynamic> missingIndexes;
  final List<dynamic> unusedIndexes;
  final List<dynamic> tableBloat;
  final DateTime lastUpdated;

  HealthData({
    required this.healthOverview,
    required this.missingIndexes,
    required this.unusedIndexes,
    required this.tableBloat,
    required this.lastUpdated,
  });
}